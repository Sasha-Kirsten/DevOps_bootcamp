module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "21.1.3"


    cluster_name    = var.cluster_name
    kubernetes_version = var.kubernetes_version
    subnet_id = var.subnet_id

    vpc_id = resource.aws_vpc.main.id

    tags = {
        Name = var.cluster_name
        environment = var.environment
        application = var.application
    }

    eks_managed_node_groups = {
        example = {
            ami_type = "AL2_x86_64" # Example AMI type  
            instance_type = "t3.medium" # Example instance type
            min_size = 1
            max_size = 3
            desired_size = 2
        }
    }

    endpoint_public_access = true 
    enable_cluster_creator_admin_permissions = true

    addons = {
        coredns = {}
        eks-pod-identity-agent = {
            before_compute = true 
        }
        kube-proxy = {}
        vpn-cni = {
            before_compute = true
        }
    }




}

