variable "aws_region" {
  description = "AWS Region in which to create the state bucket."
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform state."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid 3-63 character lowercase S3 bucket name."
  }
}

variable "tags" {
  description = "Additional tags applied to bootstrap resources."
  type        = map(string)
  default = {
    Environment = "development"
  }
}