terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# This root module intentionally has no workload resources. It is the consumer
# template for shared state. Add application infrastructure here after the S3
# backend is bootstrapped and configured with `terraform init`.
#     required_version = ">= 0.12"

#     backend "s3" {
