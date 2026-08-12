resource "aws_instance" "myapp_server"{
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
        Name = "${var.vpc_name}-myapp-server"
    }

    provisioner "local-exec"{
        working_dir = "/User/aleksanderkirsten/DevOps_bootcamp/Module_15_Configuration_Management_with_Ansible/Ansible_Docker"
        command = "ansible-playbook -inventroy ${self.public_ip}, --private-key ${var.ssh_key_private} --user ec2-user deployment_docker-new-user.yaml"

    }

}


resource "null_resource" "configure_server"{
    provisioner "local-exec"{
        working_dir = "/User/aleksanderkirsten/DevOps_bootcamp/Module_15_Configuration_Management_with_Ansible/Ansible_Docker"
        command = "ansible-playbook -inventroy ${self.public_ip}, --private-key ${var.ssh_key_private} --user ec2-user deployment_docker-new-user.yaml"

    }
}
