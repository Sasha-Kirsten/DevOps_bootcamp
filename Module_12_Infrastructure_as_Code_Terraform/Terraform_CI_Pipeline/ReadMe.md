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
| `Jenkinsfile` | Declarative Jenkins pipeline that runs format, initialization, validation, and an optional reviewed plan. |
| `terraform.tfvars.example` | Safe non-secret local configuration template. |

## Pipeline Overview

The `Jenkinsfile` performs these stages:

1. **Checkout** — obtains the Terraform source.
2. **Terraform format** — runs `terraform fmt -check -recursive`.
3. **Terraform initialize** — installs providers with `-backend=false`; CI does not need shared state to validate configuration.
4. **Terraform validate** — checks Terraform syntax and internal references.
5. **Terraform plan** — optional; only runs when the `RUN_PLAN` build parameter is selected and the Jenkins agent has AWS credentials.

The optional plan is stored as `tfplan.txt` in the Jenkins build artifacts. The pipeline never runs `terraform apply` or `terraform destroy`.

The pipeline helps ensure Terraform configurations are correctly formatted, validated, and safe to review before infrastructure changes are applied.

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
├── Jenkinsfile
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

Create a **Pipeline** or **Multibranch Pipeline** job that points to this repository. The Jenkins agent requires Terraform $\ge 1.5$, Git, and network access to the Terraform Registry. Use the default Pipeline script path, `Jenkinsfile`.

Use the default `RUN_PLAN=false` setting for pull requests and routine CI builds. This runs fully offline from AWS account changes: it installs providers, packages the local Lambda function, and validates the configuration.

Enable `RUN_PLAN` only for an approved build with AWS credentials supplied by Jenkins Credentials, an instance profile, or an assumed role. The identity needs read access sufficient for Terraform to refresh the resources it plans. Do not place AWS keys in source files or in `terraform.tfvars`.

### Run the validation build in Jenkins

This is the first build to run and it does **not** call AWS:

1. In Jenkins, select **New Item** and create a **Pipeline** job, for example `terraform-ci-api-validation`.
2. In **Pipeline**, select **Pipeline script from SCM**, choose Git, and set the repository URL to `https://github.com/Sasha-Kirsten/DevOps_bootcamp.git`.
3. Select branch `main` and keep the script path as `Jenkinsfile`.
4. Configure the job's working directory to `Module_12_Infrastructure_as_Code_Terraform/Terraform_CI_Pipeline` if the Jenkins SCM configuration or job plugin supports it. Otherwise, use a Multibranch Pipeline job whose repository root is this project directory.
5. Confirm that the selected Jenkins agent provides `git` and Terraform $\ge 1.5$.
6. Select **Build with Parameters**, leave `RUN_PLAN` unchecked, and run the build.

The expected green stages are **Checkout**, **Terraform format**, **Terraform initialize**, and **Terraform validate**. Save a screenshot of the stage view and a redacted console-log excerpt for the portfolio evidence.

> **Important:** A Pipeline job checking out the repository root cannot find this project's `Jenkinsfile` automatically because it is stored in a subdirectory. Either configure Jenkins to use the exact script path `Module_12_Infrastructure_as_Code_Terraform/Terraform_CI_Pipeline/Jenkinsfile`, or create a separate repository for this portfolio project. In both cases, ensure shell steps execute from `Module_12_Infrastructure_as_Code_Terraform/Terraform_CI_Pipeline`.

### Enable a reviewed plan safely

Use a disposable AWS development account or a clearly isolated development environment. Do not use personal long-lived access keys in Jenkins.

1. Create an IAM role for the Jenkins **agent**, such as `terraform-ci-plan-reviewer`, and attach the example policy in [`jenkins/terraform-plan-reviewer-policy.json`](jenkins/terraform-plan-reviewer-policy.json).
2. Use a short-lived workload identity to provide that role to the Jenkins agent: an EC2 instance profile, EKS IRSA, or another approved federated role. If a separate Jenkins-agent role assumes `terraform-ci-plan-reviewer`, allow only `sts:AssumeRole` to that specific target role.
3. Start with the exact template policy. If AWS denies an additional read API during planning, add only that documented read action; do not replace the policy with administrative access.
4. Confirm that the Jenkins agent is using the intended AWS account and Region before selecting `RUN_PLAN=true`. The configured default Region is defined in `terraform.tfvars.example`.
5. Select **Build with Parameters**, check `RUN_PLAN`, and run the build. Jenkins creates `tfplan` and archives the readable `tfplan.txt` artifact; it does not apply it.
6. Review the plan before sharing it. Redact account IDs, API URLs, ARNs, resource IDs, internal hostnames, and any values marked sensitive. Keep the redacted text file or screenshot as portfolio evidence.

The plan-role policy intentionally allows only the read calls used by this Lambda/API Gateway configuration and `sts:GetCallerIdentity`. It contains no Terraform apply permissions such as `lambda:CreateFunction`, `apigateway:POST`, `iam:CreateRole`, or `logs:CreateLogGroup`.

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

## Presentation Evidence Checklist

Use these artifacts to explain the project without exposing account IDs, URLs, plan details, or credentials:

1. Show the architecture diagram and explain the Lambda-to-API-Gateway request path.
2. Show `Jenkinsfile` and point out that `RUN_PLAN` defaults to `false` and the pipeline contains no `terraform apply` command.
3. Capture a successful Jenkins validation build with the format, initialize, and validate stages. If you demonstrate a plan, redact sensitive/account-specific data from `tfplan.txt`.
4. Show `serverless.tf` to discuss reproducible Lambda packaging, CloudWatch logging permissions, API Gateway integration permission, tagging, and throttling.
5. Demonstrate the Lambda handler locally with a sample API Gateway event and its HTTP `200` JSON response.

Current local verification for this revision:

- `terraform fmt -check -recursive` passed.
- `terraform init -backend=false -input=false` passed using the provider lock selections.
- `terraform validate -no-color` passed.
- `python -m py_compile lambda_function.py` passed.
- A local `lambda_handler` invocation returned HTTP `200`, JSON content, and the supplied request path.

No Terraform plan, apply, destroy, or AWS resource changes were run during these checks.