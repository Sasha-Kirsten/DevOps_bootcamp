# Infrastructure as Code (IaC) and Terraform — Theory + Practical DevOps Notes

## Why IaC matters in DevOps
Infrastructure as Code means infrastructure is defined in version-controlled code instead of manual console clicks.

Benefits:
- reproducibility
- change reviewability
- safer team collaboration
- automated validation in CI/CD
- faster, consistent environment provisioning

For DevOps, IaC is the foundation for reliable platform delivery.

---

## 1) IaC fundamentals (theory)

### Declarative vs imperative
- **Declarative**: define desired end state (Terraform style).
- **Imperative**: define step-by-step commands.

Terraform is declarative: it calculates actions required to reach desired state.

### Idempotency
Running the same Terraform code repeatedly should converge to the same state without unintended side effects.

### Drift
Drift happens when real cloud resources differ from IaC definitions.

Common causes:
- manual console changes
- unmanaged resources added outside Terraform
- changed defaults in providers/APIs

---

## 2) Terraform core concepts

### Providers
Plugins that interact with APIs (e.g., AWS, Azure, GCP).

### Resources
Managed infrastructure objects (e.g., VPC, subnet, EC2, EKS).

### Data sources
Read-only lookups for existing information (e.g., latest AMI).

### Variables
Parameterize environment-specific values.

### Outputs
Expose useful deployment values (e.g., public IP, endpoint URL).

### State
Terraform state maps code to real resources.

---

## 3) Terraform lifecycle commands (practical)

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform destroy
```

Recommended safe order:
1. `init`
2. `fmt -check`
3. `validate`
4. `plan`
5. review
6. `apply` only after approval

---

## 4) Recommended repository structure

```text
terraform-project/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── provider.tf
├── terraform.tfvars.example
├── modules/
│   ├── network/
│   └── compute/
└── README.md
```

Add `.gitignore` entries:
```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
terraform.tfvars
crash.log
```

Never commit real credentials or state files.

---

## 5) Terraform state strategy (critical)

### Local state (learning only)
Good for solo local practice, risky for teams.

### Remote state (team standard)
Use remote backend with:
- encryption
- versioning
- locking
- least-privilege access

AWS example pattern:
- S3 bucket for state
- S3 native lockfile support (`use_lockfile = true`) or DynamoDB lock table (older approach)

Backend example:
```hcl
terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bucket"
    key          = "envs/dev/network/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

## 6) Terraform language essentials (practical)

### Minimal AWS example
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

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "logs" {
  bucket = "my-unique-logs-bucket-12345"
  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

### Variables example
```hcl
variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "eu-central-1"
}

variable "environment" {
  type        = string
  description = "Environment name"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev/staging/prod"
  }
}
```

### Outputs example
```hcl
output "logs_bucket_name" {
  value       = aws_s3_bucket.logs.id
  description = "S3 bucket name for logs"
}
```

---

## 7) Modules and reuse patterns

### Why modules
- remove duplication
- enforce standard architecture
- improve maintainability

### Module contract rule
A child module should:
- receive dependencies via inputs
- return only needed outputs
- avoid provider credentials and environment-specific secrets

Module usage example:
```hcl
module "network" {
  source              = "./modules/network"
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
```

---

## 8) Environment strategy for IaC

Use separate state and variables for each environment.

Typical options:
1. separate folders (`environments/dev`, `staging`, `prod`)
2. separate state keys/backends
3. separate cloud accounts/subscriptions (strongly recommended)

Avoid applying production from a developer laptop.

---

## 9) Terraform in CI/CD pipelines

### Validation-first pipeline
1. `terraform fmt -check -recursive`
2. `terraform init -backend=false`
3. `terraform validate`
4. optional `terraform plan` with approved cloud identity
5. archive plan output
6. apply only with approval gates

### Jenkins stage example
```groovy
stage('Terraform Validate') {
  steps {
    sh 'terraform fmt -check -recursive'
    sh 'terraform init -backend=false -input=false'
    sh 'terraform validate -no-color'
  }
}
```

### GitHub Actions concept snippet
```yaml
- name: Terraform fmt
  run: terraform fmt -check -recursive

- name: Terraform init (no backend)
  run: terraform init -backend=false -input=false

- name: Terraform validate
  run: terraform validate -no-color
```

---

## 10) Security best practices for Terraform

1. Use short-lived credentials (assume role / federated identity).
2. Never hardcode cloud keys in `.tf` files.
3. Mark sensitive inputs as `sensitive = true` when appropriate.
4. Encrypt remote state and restrict access.
5. Avoid leaking secrets in outputs and logs.
6. Use least-privilege IAM for plan/apply identities.
7. Add policy checks and security scanning in CI.

Sensitive variable example:
```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

---

## 11) Policy and compliance in IaC workflows

Common controls:
- OPA/Conftest
- Checkov
- tfsec
- Sentinel (Terraform Cloud/Enterprise)

Examples of policy checks:
- deny public S3 buckets
- deny `0.0.0.0/0` SSH ingress
- require tags: owner, environment, cost-center
- enforce encryption at rest

---

## 12) Practical AWS networking IaC baseline

A common baseline architecture:
- VPC
- public and private subnets (multi-AZ)
- internet gateway
- NAT gateway for private egress
- route tables + associations
- security groups with least privilege

Key DevOps note:
NAT gateways are reliable but can be costly; clean up unused labs.

---

## 13) Planning and change review discipline

### Plan workflow
```bash
terraform plan -out=tfplan
terraform show tfplan
```

Benefits:
- auditable, exact proposed changes
- safer approvals
- deterministic apply (`terraform apply tfplan`)

Avoid applying unreviewed plans in shared/production environments.

---

## 14) Drift detection and reconciliation

Useful commands:
```bash
terraform plan
terraform refresh   # older workflows; often plan handles refresh behavior
terraform state list
```

If drift is detected:
1. determine whether manual change is valid
2. either codify the change in IaC
3. or revert cloud resource to match IaC

Never ignore persistent drift in production systems.

---

## 15) Troubleshooting runbook

### `terraform init` fails
- check provider version constraints
- check network/proxy access to provider registry
- remove `.terraform` and re-init if needed

### `terraform validate` fails
- inspect file/line references
- check variable types and missing attributes

### `terraform plan` fails with auth errors
- verify account/role identity:
```bash
aws sts get-caller-identity
```
- ensure IAM permissions match resources being planned

### Resource replacement surprises
- read plan output for `-/+` changes
- use lifecycle/meta-arguments only when justified

---

## 16) High-value Terraform commands cheat sheet

```bash
# formatting and validation
terraform fmt -recursive
terraform validate

# inspect values
terraform output
terraform output -raw <name>

# state inspection
terraform state list
terraform state show <resource_address>

# graph (for dependency visualization)
terraform graph

# destroy lab resources safely
terraform destroy
```

---

## 17) Common anti-patterns to avoid

- committing `terraform.tfstate` to Git
- using one shared admin account for all environments
- no remote state locking in team environments
- manual console changes without code updates
- giant monolithic modules with no boundaries
- overusing `-target` except emergency cases
- unmanaged secrets in plain text variables

---

## 18) Practical DevOps checklist for IaC/Terraform

- [ ] IaC code reviewed by pull request
- [ ] Provider and Terraform versions pinned
- [ ] Remote state encrypted + locked
- [ ] Separate state per environment
- [ ] Validation and plan in CI
- [ ] Security/policy scans in CI
- [ ] Apply gated with approval in protected envs
- [ ] Cost-impact awareness for major resources
- [ ] Rollback/recovery strategy documented

---

## 19) Example end-to-end IaC workflow

1. Create feature branch
2. Edit Terraform code
3. Run local checks:
   - `terraform fmt -check -recursive`
   - `terraform init -backend=false`
   - `terraform validate`
4. Open pull request
5. CI runs same validation + security scans
6. Generate reviewed plan in dev account
7. Approval gate
8. Apply approved plan
9. Verify outputs and smoke checks
10. Document and monitor

---

## 20) Suggested additions for Module 12 projects

Add reusable automation scripts:
- `scripts/tf-validate.sh`
- `scripts/tf-plan-dev.sh`
- `scripts/tf-apply-approved-plan.sh`
- `scripts/tf-destroy-lab.sh`
- `scripts/check-aws-identity.sh`

Add documentation:
- `runbooks/terraform-incident-response.md`
- `security/terraform-policy-rules.md`
- `cost/terraform-lab-cost-checklist.md`

These additions improve consistency and recruiter readability.

---

## References

- Terraform docs: https://developer.hashicorp.com/terraform/docs
- Terraform language: https://developer.hashicorp.com/terraform/language
- Terraform state: https://developer.hashicorp.com/terraform/language/state
- AWS provider docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Terraform S3 backend: https://developer.hashicorp.com/terraform/language/backend/s3
- AWS Well-Architected: https://docs.aws.amazon.com/wellarchitected/
