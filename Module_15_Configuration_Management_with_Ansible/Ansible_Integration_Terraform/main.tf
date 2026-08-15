resource "null_resource" "configure_server"{
    provisioner "local-exec"{
        working_dir = "/User/aleksanderkirsten/DevOps_bootcamp/Module_12_Infrastructure_as_Code_Terraform/Complete_CI_CD_with_Terraform"
        command = "ansible-playbook -inventroy ${self.public_ip}, --private-key ${var.ssh_key_private} --user ec2-user deployment_docker-new-user.yaml"

    }
}