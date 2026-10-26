resource "null_resource" "configure_server"{
    # TODO(idempotency): Trigger configuration from the EC2 instance ID and a hash of playbook/role files, not every
    # Terraform apply. Example inputs: aws_instance.myapp_server.id and filesha256("${path.module}/playbook.yaml").
    # TODO(dependency): Reference the EC2 resource directly or use depends_on so Ansible starts only after the host exists.
    provisioner "local-exec"{
        # TODO(portability): Use path.module rather than an absolute /Users/... path from a different project.
        working_dir = "/User/aleksanderkirsten/DevOps_bootcamp/Module_12_Infrastructure_as_Code_Terraform/Complete_CI_CD_with_Terraform"
        # TODO(correctness): Use `-i`, aws_instance.myapp_server.public_ip with a trailing comma, and playbook.yaml.
        # TODO(security): Inject the SSH-key path through an ignored local value or CI/CD secret; never commit it in tfvars.
        command = "ansible-playbook -inventroy ${self.public_ip}, --private-key ${var.ssh_key_private} --user ec2-user deployment_docker-new-user.yaml"

    }
}