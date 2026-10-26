output "cluster_name" {
  description = "Provisioned EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Kubernetes API endpoint. Treat as environment metadata."
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group associated with the EKS control plane."
  value       = module.eks.cluster_security_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl after a successful apply."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}