# Terraform CI Pipeline

This project demonstrates a CI pipeline for validating Terraform infrastructure code automatically.

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
├── .github/
│   └── workflows/
│       └── terraform-ci.yml
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example
└── ReadMe.md
```

> File names may differ depending on the project configuration.

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

## CI Workflow Example

A GitHub Actions workflow can run Terraform checks automatically:

```yaml
name: Terraform CI

on:
    pull_request:
        branches:
            - main
    push:
        branches:
            - main

jobs:
    terraform:
        name: Terraform Validation
        runs-on: ubuntu-latest

        steps:
            - name: Checkout repository
                uses: actions/checkout@v4

            - name: Set up Terraform
                uses: hashicorp/setup-terraform@v3

            - name: Terraform Init
                run: terraform init -input=false

            - name: Terraform Format Check
                run: terraform fmt -check -recursive

            - name: Terraform Validate
                run: terraform validate

            - name: Terraform Plan
                run: terraform plan -input=false
```

Save the workflow file in:

```text
.github/workflows/terraform-ci.yml
```

## Secrets and Sensitive Values

Do not store cloud credentials, API keys, passwords, or `terraform.tfvars` files containing sensitive data in the repository.

Use GitHub Actions secrets instead:

1. Open the repository on GitHub.
2. Go to **Settings** → **Secrets and variables** → **Actions**.
3. Add the required credentials as repository secrets.
4. Reference secrets in the workflow using:

```yaml
${{ secrets.SECRET_NAME }}
```

Example:

```yaml
env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

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

Some providers need credentials even when creating a plan. Configure the required environment variables locally or add them as GitHub Actions secrets for the CI workflow.

## Suggested Workflow Improvements

For production-oriented projects, consider adding the following improvements:

- Pin Terraform and provider versions to make builds reproducible.
- Use a remote backend, such as Amazon S3, Azure Storage, or Terraform Cloud, for shared state.
- Run `terraform plan -out=tfplan` and preserve the plan as a workflow artifact.
- Require pull-request reviews before merging infrastructure changes.
- Use separate state files or workspaces for each environment.
- Add security scanning tools such as `tfsec`, `Checkov`, or `Trivy`.
- Apply changes only from protected branches after an approved plan review.

## Example Version Constraints

Define Terraform and provider versions in a `versions.tf` file:

```hcl
terraform {
    required_version = ">= 1.6.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}
```

Version constraints help prevent unexpected behavior caused by incompatible Terraform or provider releases.

## CI Status

After the workflow is added, GitHub Actions displays the result for every configured push and pull request. A successful workflow confirms that the Terraform configuration was initialized, formatted correctly, validated, and planned without errors.

A successful plan does not apply infrastructure changes. Review the plan output and approval requirements before running any apply step.