# Terraform CI Pipeline with Jenkins

This project demonstrates a Jenkins-based CI pipeline for a small serverless AWS API. Terraform packages a Python Lambda function, configures an API Gateway `GET /health` endpoint, and defines the IAM permissions required for the integration.

The Jenkins pipeline is validation-first: every build checks formatting and Terraform configuration without modifying AWS infrastructure. An optional plan stage can be enabled only after AWS credentials have been configured safely in Jenkins.

## Architecture

```text
Client
    |
    | GET /<stage>/health
    v
API Gateway (Regional)
    |
    v
AWS Lambda (Python 3.12)
    |
    v
CloudWatch Logs
```

## What the Configuration Includes

| File | Purpose |
| --- | --- |
| `serverless.tf` | Active Lambda, API Gateway, IAM, and deployment resources. |
| `main.tf` | Preserved legacy draft for comparison; it is fully commented out and not evaluated by Terraform. |
| `provider.tf` | Terraform, AWS provider, archive provider, and AWS Region configuration. |
| `variables.tf` | Reusable inputs for naming, region, API stage, Lambda capacity, throttling, and tags. |
| `lambda_function.py` | Lambda handler packaged into a ZIP by the archive provider. |
| `outputs.tf` | Lambda function name and API invocation URL. |
| `jenkinsfile` | Declarative Jenkins pipeline. Configure this lower-case path explicitly in Jenkins, or rename it to `Jenkinsfile` if using the default pipeline script path. |
| `terraform.tfvars.example` | Safe non-secret local configuration template. |

## Pipeline Overview

The `jenkinsfile` performs these stages:

1. **Checkout** — obtains the Terraform source.
2. **Terraform format** — runs `terraform fmt -check -recursive`.
3. **Terraform initialize** — installs providers with `-backend=false`; CI does not need shared state to validate configuration.
4. **Terraform validate** — checks Terraform syntax and internal references.
5. **Terraform plan** — optional; only runs when the `RUN_PLAN` build parameter is selected and the Jenkins agent has AWS credentials.

The optional plan is stored as `tfplan.txt` in the Jenkins build artifacts. The pipeline never runs `terraform apply` or `terraform destroy`.

The pipeline helps ensure Terraform configurations are correctly formatted, validated, and safe to review before infrastructure changes are applied.

## Pipeline Overview

The CI pipeline runs on pull requests and pushes to the main branch.

Typical stages include:

1. **Checkout source code**
2. **Set up Terraform**
3. **Initialize Terraform**
4. **Check Terraform formatting**
5. **Validate Terraform configuration**
6. **Run Terraform plan**
7. **Publish plan output for review** (optional)

## Prerequisites

Before running this project locally, install:

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- Git
- Cloud provider CLI tools, if required by the Terraform provider

Verify Terraform is installed:

```bash
terraform version
```

## Project Structure

```text
Terraform_CI_Pipeline/
├── jenkinsfile
├── main.tf
├── serverless.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── lambda_function.py
├── terraform.tfvars.example
├── .gitignore
└── ReadMe.md
```

## Local Usage

### 1. Clone the repository

```bash
git clone https://github.com/Sasha-Kirsten/DevOps_bootcamp.git
cd DevOps_bootcamp/Module_12_Infrastructure_as_Code_Terraform/Terraform_CI_Pipeline
```

### 2. Initialize Terraform

```bash
terraform init
```

This command downloads the required providers and prepares the working directory.

### 3. Format Terraform files

```bash
terraform fmt -recursive
```

To check formatting without modifying files:

```bash
terraform fmt -check -recursive
```

### 4. Validate the configuration

```bash
terraform validate
```

### 5. Review the execution plan

```bash
terraform plan
```

Terraform will display the infrastructure changes it would make without applying them.

## Configure Jenkins

Create a **Pipeline** or **Multibranch Pipeline** job that points to this repository. The Jenkins agent requires Terraform $\ge 1.5$, Git, and network access to the Terraform Registry. For the current lower-case filename, set the pipeline **Script Path** to:

```text
jenkinsfile
```

Use the default `RUN_PLAN=false` setting for pull requests and routine CI builds. This runs fully offline from AWS account changes: it installs providers, packages the local Lambda function, and validates the configuration.

Enable `RUN_PLAN` only for an approved build with AWS credentials supplied by Jenkins Credentials, an instance profile, or an assumed role. The identity needs read access sufficient for Terraform to refresh the resources it plans. Do not place AWS keys in source files or in `terraform.tfvars`.

## Secrets and Sensitive Values

Do not store cloud credentials, API keys, passwords, or `terraform.tfvars` files containing sensitive data in the repository.

For Jenkins, configure cloud access through an AWS-aware credential binding, a short-lived assumed role, or an instance profile. Do not echo credentials in build logs. Keep `RUN_PLAN` disabled until this access is available.

## Recommended Practices

- Run `terraform fmt` before committing changes.
- Run `terraform validate` before opening a pull request.
- Review every `terraform plan` output carefully.
- Store Terraform state remotely for team environments.
- Use state locking to prevent concurrent infrastructure changes.
- Keep credentials in a secrets manager or CI/CD secret store.
- Separate development, staging, and production environments.

## Useful Commands

```bash
# Initialize Terraform
terraform init

# Format files
terraform fmt -recursive

# Validate configuration
terraform validate

# Create an execution plan
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy managed infrastructure
terraform destroy
```

> Use `terraform apply` and `terraform destroy` carefully, especially in shared or production environments.

## License

This project is created for educational purposes as part of the DevOps Bootcamp.
## Troubleshooting

### `terraform init` fails

Confirm that Terraform can access the provider registry and that the configured provider credentials are available. If a previous initialization is corrupted, remove the local Terraform directory and initialize again:

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init
```

### Formatting check fails in CI

Run the formatter locally, review the changes, and commit the updated files:

```bash
terraform fmt -recursive
git diff
```

### Validation fails

Run validation locally after initialization:

```bash
terraform init -input=false
terraform validate
```

Read the reported file name and line number, correct the configuration, then rerun the command.

### Plan requires cloud credentials

AWS provider refreshes during a plan require credentials. Configure an AWS identity through Jenkins Credentials, an assumed role, or an instance profile. Keep the default `RUN_PLAN=false` setting when the CI job does not have approved AWS access.

## Suggested Workflow Improvements

For production-oriented projects, consider adding the following improvements:

- Commit `.terraform.lock.hcl` after provider initialization to make provider selection reproducible.
- Use a remote backend, such as Amazon S3, Azure Storage, or Terraform Cloud, for shared state.
- Run `terraform plan -out=tfplan` and preserve the plan as a workflow artifact.
- Require pull-request reviews before merging infrastructure changes.
- Use separate state files or workspaces for each environment.
- Add security scanning tools such as `tfsec`, `Checkov`, or `Trivy`.
- Apply changes only from protected branches after an approved plan review.

## CI Result

A successful Jenkins build confirms that Terraform was formatted correctly, initialized with the required providers, and validated. If `RUN_PLAN` was selected and AWS credentials were available, the build also archives a readable plan for review.

A successful plan never applies infrastructure changes. Keep `terraform apply` outside this validation job and run it only through an approved deployment workflow.