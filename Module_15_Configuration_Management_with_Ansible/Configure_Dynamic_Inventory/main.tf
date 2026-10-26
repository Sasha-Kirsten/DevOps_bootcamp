# PRODUCTION: Pin Terraform/AWS provider versions and use encrypted remote state with locking
# before sharing this configuration. Keep network, IAM, provider, and variable definitions in
# dedicated files instead of relying on undeclared resources/variables in a single file.
resource "aws_instance" "myapp_server-one"{
    # PRODUCTION: Run workloads in private subnets; avoid public IPs and inbound SSH. Use SSM
    # Session Manager or a tightly controlled bastion/VPN path for administrative access.
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    availability_zone = var.availability_zone
    
    associate_public_ip_address = true # PRODUCTION: Set false for private application instances.
    key_name = var.key_name 

    # PRODUCTION: Keep first-boot initialization small and idempotent. Store a reviewed script in
    # source control, prefer cloud-init, and let Ansible own ongoing application configuration.
    user_data = file("server-cmds.sh")

    user_data_replace_on_change = true

    tags = {
        # PRODUCTION: Dynamic inventory should filter on stable tags such as Environment,
        # Project, Role, Owner, and ManagedBy—not a Name wildcard. These tags make target
        # selection auditable and prevent a playbook in a shared AWS account from reaching
        # unintended running instances.
        Name = "${var.vpc_name}-myapp-server-one"
    }
}

resource "aws_instance" "myapp_server-two"{
    # PRODUCTION: Require IMDSv2, encrypt EBS volumes with a customer-managed KMS key where
    # required, attach the least-privilege instance profile, and enable backup/log collection.
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    availability_zone = var.availability_zone
    
    associate_public_ip_address = true
    key_name = var.key_name 

    user_data = file("server-cmds.sh")

    user_data_replace_on_change = true

    tags = {
        # PRODUCTION: Use the same mandatory tag schema on every resource, including volumes,
        # security groups, and load balancers, so automation and cost ownership stay consistent.
        Name = "${var.vpc_name}-myapp-server-two"
    }
}


resource "aws_instance" "myapp_server-three"{
    # PRODUCTION: Restrict the attached security group to required ports and trusted sources.
    # Prefer application load balancers and private service-to-service connectivity over direct
    # exposure of individual instances.
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.web_sg.id]
    availability_zone = var.availability_zone
    
    associate_public_ip_address = true
    key_name = var.key_name 

    user_data = file("server-cmds.sh")

    user_data_replace_on_change = true

    tags = {
        # PRODUCTION: Give this instance an explicit Role tag (for example, Role = "docker") so
        # Ansible can generate a role-specific group rather than relying on the plugin name.
        Name = "${var.vpc_name}-myapp-server-three"
    }
}