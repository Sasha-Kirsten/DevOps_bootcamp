provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

resource "aws_vpc" "vpc1"{
    cidr_block = "10.0.0.0.0.0/16"
}

resource "aws_subnet" "public_subnet1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private_subnet1" {
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.2.0/24"
    security_group_ids = [aws_security_group.private_sg.id]
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc1.id
}

resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.public_subnet1.id
}

resource "aws_security_group" "private_sg"{
    vpc_id = aws_vpc.vpc1.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [""]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [""]
    }
}

resource "aws_security_group" "public_sg" {
    vpc_id = aws_vpc.vpc1.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [""]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = [""]
    }
}

resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.vpc1.id
    nat_gateway_id = aws_nat_gateway.nat_gw.id
    security_group_id = aws_security_group.public_sg.id
}

resource "aws_ami" "my_ami" {
    name = "my-ami"
    virtualization_type = "hvm"
    root_device_name = "/dev/sda1"
    ebs_block_device {
        device_name = "/dev/sda1"
        volume_size = 8
        volume_type = "gp2"
    }
}

resource "aws_instance" "public_instance1" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public_subnet1.id
    security_groups = [aws_security_group.public_sg.name]

    associate_public_ip_address = true
    key_name = "my-key-pair"

    user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y && sudo yum install -y docker
                sudo systemctl start docker
                sudo usermod -aG docker ec2-user
                docker run -p 8080:80 nginx 
                EOF
}

resource "aws_instance" "private_instance1" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.private_subnet1.id
    security_groups = [aws_security_group.private_sg.name]

    user_data = <<-EOF
                #!/bin/bash
                
                EOF
}



