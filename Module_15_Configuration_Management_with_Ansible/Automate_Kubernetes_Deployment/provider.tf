provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Application = var.application
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# AWS credentials must come from the standard provider chain, such as an AWS
# profile, IAM Identity Center, or an assumed role. Never commit credentials.
