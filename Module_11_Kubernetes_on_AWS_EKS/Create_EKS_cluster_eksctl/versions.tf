terraform {
  required_version = ">= # TODO: minimum Terraform version"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> # TODO: provider version"
    }
  }

  # Optional: configure only after creating your remote-state backend.
  # backend "s3" {
  #   bucket         = ""
  #   key            = ""
  #   region         = ""
  #   dynamodb_table = ""
  #   encrypt        = true
  # }
}