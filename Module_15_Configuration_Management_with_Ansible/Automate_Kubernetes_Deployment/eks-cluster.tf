resource "aws_eks_cluster" "example" {

    name = var.cluster_name
    kubernetes_version = var.kubernetes_version

    subnet_ids = [var.subnet_id]
    vpc_id = var.vpc_id

    endpoint_public_access = true
    enable_cluster_creator_admin_permissions = true

    eks_managed_node_groups = {
        example = {
            ami_type = "AL2_x86_64" # Example AMI type  
            instance_type = "t3.medium" # Example instance type
            min_size = 1
            max_size = 3
            desired_size = 2
        }
    }

    tags = {
        Name = var.cluster_name
        environment = var.environment
        application = var.application
    }
}