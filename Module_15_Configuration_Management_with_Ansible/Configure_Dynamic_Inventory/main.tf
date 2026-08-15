resource "aws_instance" "myapp_server-one"{
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
        Name = "${var.vpc_name}-myapp-server-one"
    }
}

resource "aws_instance" "myapp_server-two"{
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
        Name = "${var.vpc_name}-myapp-server-two"
    }
}


resource "aws_instance" "myapp_server-three"{
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
        Name = "${var.vpc_name}-myapp-server-three"
    }
}