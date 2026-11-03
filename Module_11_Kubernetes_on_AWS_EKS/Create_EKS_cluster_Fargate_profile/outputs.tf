output "fargate_profile_name" {
  description = "Name of the created EKS Fargate profile."
  value       = aws_eks_fargate_profile.dev_nginx.fargate_profile_name
}

output "fargate_pod_execution_role_arn" {
  description = "IAM role assumed by EKS Fargate infrastructure to run Pods."
  value       = aws_iam_role.fargate_pod_execution.arn
}