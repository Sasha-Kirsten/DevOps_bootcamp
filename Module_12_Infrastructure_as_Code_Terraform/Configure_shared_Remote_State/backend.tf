terraform {
  backend "s3" {}
}

# Backend values cannot use Terraform variables. Configure this backend with
# `backend.hcl`, copied from backend.hcl.example, or CI backend-config options.