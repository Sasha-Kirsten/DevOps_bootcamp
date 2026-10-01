variable "aws_region" {
  description = "AWS Region in which the serverless resources are managed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used in resource names and tags."
  type        = string
  default     = "terraform-ci-api"
}

variable "environment" {
  description = "Environment name used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "api_path_part" {
  description = "Path component exposed by API Gateway."
  type        = string
  default     = "health"
}

variable "stage_name" {
  description = "API Gateway stage name."
  type        = string
  default     = "dev"
}

variable "lambda_timeout_seconds" {
  description = "Maximum Lambda execution time in seconds."
  type        = number
  default     = 10
}

variable "lambda_memory_size" {
  description = "Memory allocated to the Lambda function in MB."
  type        = number
  default     = 128
}

variable "throttling_rate_limit" {
  description = "Maximum sustained API Gateway request rate."
  type        = number
  default     = 100
}

variable "throttling_burst_limit" {
  description = "Maximum API Gateway burst request count."
  type        = number
  default     = 200
}

variable "additional_tags" {
  description = "Additional tags merged into supported AWS resources."
  type        = map(string)
  default     = {}
}