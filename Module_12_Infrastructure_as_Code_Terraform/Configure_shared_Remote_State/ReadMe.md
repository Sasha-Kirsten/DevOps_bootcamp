# Configure a Shared Remote State

## Demo project

**Demo Project:** Configure a Shared Remote State  
**Technologies Used:** Terraform, AWS S3  
**Project Description:** Configure Amazon S3 as remote storage for Terraform state.

This project demonstrates a safe, team-oriented Terraform state design. A dedicated bootstrap configuration creates a private, versioned, encrypted S3 bucket. Application Terraform configurations then use that pre-existing bucket as their shared remote backend, with native S3 lock files enabled to prevent concurrent state writes.

## Why two configurations?

Terraform must initialize its backend before it can manage resources. Therefore, a configuration cannot safely use an S3 backend that it is also trying to create. This repository separates the concern into:

| Directory | Responsibility |
| --- | --- |
| `bootstrap/` | Creates and secures the S3 bucket used to store Terraform state. It starts with local state. |
| repository root | Consumer template configured with `backend "s3" {}`. It uses the bucket only after bootstrap succeeds. |

## Security controls

The bootstrap bucket enables:

- **Versioning** to recover from accidental state overwrite or deletion.
- **Server-side encryption** using Amazon S3-managed encryption (`AES256`).
- **Block Public Access** controls for all ACL and policy paths.
- A bucket policy that denies non-TLS requests.
- **S3 lock files** (`use_lockfile = true`) for state-operation locking.

Use a dedicated AWS account or tightly scoped IAM role for state administration. Terraform state can contain sensitive infrastructure values, so it must never be public, committed to Git, or shared casually in build logs.

## Prerequisites

- Terraform `1.5` or later
- AWS CLI authenticated through IAM Identity Center or an assumed IAM role
- AWS permissions to create and administer an S3 bucket for bootstrap
- A globally unique S3 bucket name

Do not commit AWS credentials, real `terraform.tfvars`, local state files, generated plans, or `backend.hcl`. The project `.gitignore` excludes these files.

## Safe verification

These commands validate code and download provider schemas only; they do not create AWS resources:

```text
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate -no-color
```

Run the same validation commands from `bootstrap/` to verify the bucket configuration.

## Bootstrap and connect the backend

1. Copy `bootstrap/terraform.tfvars.example` to `bootstrap/terraform.tfvars` and set a globally unique bucket name.
2. In `bootstrap/`, review `terraform plan` using an approved AWS development account.
3. Apply only after approving the plan. The bucket name is returned as an output.
4. Copy `backend.hcl.example` to `backend.hcl`, replacing the bucket placeholder with the bootstrap output.
5. From the project root, initialize the remote backend with `terraform init -backend-config=backend.hcl`.

The root configuration currently contains no workload resources by design; it is a clean shared-state consumer template. Add a separate environment’s infrastructure only after the backend has been initialized.

## Jenkins pipeline

The `Jenkinsfile` runs formatting and backend-free validation on every build. It exposes these deliberate controls:

- `RUN_PLAN` defaults to `false`; enabling it requires `STATE_BUCKET` and authenticates to AWS.
- `RUN_APPLY` defaults to `false`; enabling it also creates a plan and pauses for human approval before applying it.
- The pipeline expects an **AWS Credentials** Jenkins credential with ID `aws-terraform-deployer`; use a least-privilege role and short-lived credentials.
- State bucket name and key are Jenkins parameters, not source-controlled secrets.

## Recruiter walkthrough

1. Show `bootstrap/main.tf` and explain the versioning, encryption, public-access block, and TLS-only policy.
2. Explain the bootstrap/consumer separation and why it avoids the backend initialization cycle.
3. Show `backend.tf` and `backend.hcl.example`, highlighting the environment-specific state key and lock file setting.
4. Show successful formatting and validation results.
5. Explain that an approved plan/apply uses a least-privilege AWS role and is gated by Jenkins approval.

## References

- [Terraform S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [Terraform state](https://developer.hashicorp.com/terraform/language/state)
- [Amazon S3 versioning](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Versioning.html)