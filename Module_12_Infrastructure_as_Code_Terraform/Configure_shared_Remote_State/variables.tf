variable "aws_region" {
  description = "AWS Region used by the workload configuration that consumes remote state."
  type        = string
  default     = "eu-central-1"
}
variable "vpc_cidr_block" {}
