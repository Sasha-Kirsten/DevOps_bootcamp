provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

resource "aws_subnet" "public_subnet"{
    cidr_block = var.public_subnet1
    security_groups = [aws_security_group.public_sg.name]
}

resource "aws_subnet" "private_subnet"{
    cidr_block = var.private_subnet1
    security_groups = [aws_security_group.private_sg.name]
}

resource "aws_security_group" "public_sg" {
    vpc_id = aws_vpc.vpc1.id
    ingress {
        from_port = var.public_sg_ingress_port
        to_port = var.public_sg_ingress_port
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
