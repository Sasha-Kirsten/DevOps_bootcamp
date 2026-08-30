# Infrastructure as Code (IaC) with Terraform

Infrastructure as Code (IaC) means defining and managing infrastructure through version-controlled configuration files instead of manual changes in a cloud console. Terraform is a popular IaC tool that can provision and manage resources across AWS, Azure, Google Cloud, Kubernetes, and many other providers.

Using Terraform consistently makes infrastructure changes repeatable, reviewable, and easier for a team to maintain.

> **Goal:** Treat infrastructure configuration with the same care as application code: write it, review it, test it, deploy it automatically, and document it.

## Who This Guide Is For

This guide is for learners and teams who are starting to manage cloud infrastructure with Terraform. It explains the essential Terraform workflow, the safe handling of state, and the practices needed to move from local experimentation to team-based and production deployments.

Read the guide in this order:

1. Start with **Why Use Terraform?** and the **Key Terms** if Terraform is new to you.
2. Practise the commands in **Terraform Workflow** with a small, non-production project.
3. Read **Terraform Best Practices** before working with shared cloud infrastructure.
4. Use the **Security Checklist** before applying changes to a shared or production environment.

## Key Terms

| Term | Meaning |
| --- | --- |
| **Configuration** | The `.tf` files that describe the infrastructure Terraform should manage. |
| **Provider** | A plugin that lets Terraform communicate with a platform such as AWS, Azure, or Kubernetes. |
| **Resource** | An infrastructure object managed by Terraform, such as an S3 bucket, virtual machine, or network. |
| **State** | Terraform's record of the real resources it manages and their relationships. |
| **Backend** | The location and mechanism Terraform uses to store state, such as a local file or an S3 bucket. |
| **Plan** | A preview of the changes Terraform proposes to make. |
| **Apply** | The command that performs the reviewed infrastructure changes. |
| **Module** | A reusable group of Terraform configuration files. |

> **Important:** Terraform can create, modify, and destroy real cloud resources. Begin with a low-cost learning environment, review every plan, and clean up resources when they are no longer needed.

## Why Use Terraform?

Terraform helps teams to:

- Create the same infrastructure repeatedly across development, test, staging, and production environments.
- Track infrastructure changes in Git history.
- Review changes before they are applied.
- Reduce manual configuration mistakes.
- Recreate infrastructure during a recovery or migration.
- Use one workflow for multiple cloud providers and services.

## Terraform Workflow

The standard Terraform workflow has five main commands:

```bash
# Download provider plugins and initialize the configured backend
terraform init

# Format configuration files consistently
terraform fmt

# Validate Terraform configuration syntax and internal references
terraform validate

# Preview the infrastructure changes Terraform would make
terraform plan

# Apply the reviewed changes
terraform apply
```

Run `terraform plan` before every `terraform apply`. The plan is the opportunity to confirm that Terraform will create, change, or destroy only the intended resources. For shared environments, save the approved plan to a file and apply that exact file rather than generating a different plan later:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

The `apply` command changes real infrastructure. Never add `-auto-approve` to an interactive learning workflow; reserve non-interactive applies for protected automation that has already completed the required reviews and approvals.

## Terraform Best Practices

### 1. Manipulate State Only Through Terraform Commands

Terraform stores information about managed resources in a state file, usually called `terraform.tfstate`. This state connects the Terraform configuration to the real infrastructure.

Do **not** edit the state file by hand. Manual edits can corrupt the state or cause Terraform to create duplicate resources, delete the wrong resource, or lose track of existing infrastructure.

Use Terraform commands instead:

```bash
# Show resources tracked by Terraform
terraform state list

# Inspect one resource in the state
terraform state show <resource-address>

# Move a resource address after refactoring configuration
terraform state mv <source-address> <destination-address>

# Remove a resource only from state management
terraform state rm <resource-address>
```

Use `terraform state rm` carefully: it removes Terraform's record of the resource but does not delete the real cloud resource.

### 2. Always Use Shared Remote State Storage

Local state files work for learning projects but are not safe for team collaboration. Store the state remotely so that every approved workflow uses the same source of truth.

For AWS, a common backend uses an S3 bucket. The bucket should be private, encrypted, versioned, and accessible only to the people and automation that need it.

```hcl
terraform {
	backend "s3" {
		bucket  = "<unique-terraform-state-bucket>"
		key     = "environments/dev/terraform.tfstate"
		region  = "<aws-region>"
		encrypt = true
	}
}
```

Initialize or migrate the backend after adding this configuration:

```bash
terraform init
```

Never commit a local `terraform.tfstate` file to Git. Add it to `.gitignore` instead.

### 3. Use State Locking

State locking prevents two users or CI/CD pipelines from writing to the same state at the same time. Without locking, concurrent changes can overwrite state or leave infrastructure in an inconsistent condition.

Use a backend that supports locking. For AWS S3 backends, configure locking according to the Terraform version and your organisation's AWS standards. Always ensure that only one `terraform apply` runs against a specific environment state at a time.

If a run fails and leaves a lock behind, investigate first. Only use `terraform force-unlock` when you are certain that no other Terraform operation is still running.

### 4. Back Up State Files

A state file may contain infrastructure metadata and, depending on the resources used, sensitive values. Protect it as carefully as production configuration.

When using S3 for the backend:

- Enable bucket versioning so a previous state version can be recovered.
- Enable server-side encryption.
- Restrict bucket access with least-privilege IAM policies.
- Enable logging and monitoring for the state bucket where required.
- Keep tested backup and recovery procedures.

Do not share state files through email, chat, or public repositories.

### 5. Use One State File per Environment

Keep environments isolated. Development, test, staging, and production should not share one state file because a change intended for development could otherwise affect production.

A simple layout is:

```text
environments/
├── dev/
├── test/
├── staging/
└── prod/
```

Each environment can have its own backend key, variables, and approved deployment pipeline. Terraform workspaces can be helpful for simple use cases, but separate directories and separate remote-state keys are often easier to understand and protect for long-lived production environments.

### 6. Store Terraform Code in Git

Host Terraform code in a Git repository to enable collaboration, history, code review, and rollback of configuration changes.

Recommended practices:

- Use pull requests for infrastructure changes.
- Protect the default branch and production deployment branches.
- Write meaningful commit messages.
- Keep provider and module versions pinned to tested versions.
- Do not commit credentials, API keys, or `.tfvars` files that contain secrets.
- Use `.gitignore` to exclude state files, plan files, and local Terraform working data.

Example `.gitignore` entries:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
crash.log
*.tfvars
*.tfvars.json
```

> **Note:** Commit an example such as `terraform.tfvars.example` so teammates know which variables are required without exposing real values.

### 7. Use Continuous Integration for Terraform Code

Treat Terraform code like application code. A continuous integration (CI) pipeline should automatically check every pull request before it can be merged.

A typical CI pipeline runs:

1. `terraform fmt -check` to enforce formatting.
2. `terraform init -backend=false` to download providers without accessing the remote state.
3. `terraform validate` to verify the configuration.
4. `terraform plan` to preview expected changes when suitable credentials and a safe backend are available.
5. Security and policy scans, such as checks for public storage buckets or overly permissive firewall rules.

Publish the plan output for reviewers, but make sure it does not expose sensitive data.

### 8. Apply Infrastructure Changes Only Through a CD Pipeline

Use a controlled continuous deployment (CD) pipeline for `terraform apply`, especially for staging and production. Avoid applying production changes from a developer laptop.

A safe deployment flow is:

1. A pull request is reviewed and validated by CI.
2. The approved change is merged to a protected branch.
3. The CD pipeline generates a new Terraform plan.
4. An authorised reviewer approves the production deployment when required.
5. The pipeline applies the exact reviewed plan using a dedicated service identity.
6. The pipeline records the result and alerts the team if the deployment fails.

The deployment identity should use least-privilege permissions. Prefer short-lived credentials or workload identity over long-lived access keys.

## Project Structure Example

A small Terraform project can begin with this structure:

```text
terraform-aws-project/
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   └── variables.tf
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       └── variables.tf
├── modules/
│   └── network/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── .gitignore
├── README.md
└── versions.tf
```

Use modules for reusable groups of resources, such as networking, compute, databases, or Kubernetes clusters. Keep modules small, documented, and independently testable.

## Security Checklist

Before applying infrastructure changes, verify the following:

- [ ] The remote state backend is private, encrypted, versioned, and locked.
- [ ] Each environment uses a separate state file and access policy.
- [ ] No secrets are stored in Git, Terraform variables, or plain-text pipeline logs.
- [ ] The Terraform and provider versions are pinned and reviewed.
- [ ] The change has passed formatting, validation, planning, and security checks.
- [ ] A reviewer has checked the plan, especially resource replacements and deletions.
- [ ] Production applies run only from an approved CI/CD pipeline identity.

## Topics to Add Later

Expand this guide with project-specific examples for:

- Creating and securing an AWS S3 remote-state backend
- Configuring state locking for the selected Terraform and AWS versions
- Using reusable modules for VPCs, EC2 instances, and EKS clusters
- Managing secrets with AWS Secrets Manager, SSM Parameter Store, or a CI/CD secret store
- Adding policy-as-code and Terraform security scanning
- Building a CI/CD pipeline for `terraform plan` and `terraform apply`
- Disaster recovery and state restoration procedures
- Cost estimation and tagging standards

## Next Steps

1. Install the Terraform CLI locally or configure it in a CI/CD runner.
2. Create a small development environment, such as an AWS VPC or S3 bucket.
3. Configure a secure remote backend before collaborating with others.
4. Add CI checks for formatting and validation.
5. Create a protected deployment pipeline for staging and production.
