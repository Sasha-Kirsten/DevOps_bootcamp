terraform {
    required_version = ">= 0.12"
    backend "s3" {
        bucket = "terraform-remote-state-bucket"
        key    = "terraform.tfstate"
        region = "eu-central-1"
        availability_zone = "eu-central-1a"
    }
}

provider "aws" {
    region = var.region 
}

resource "aws_vpc" "vpc1"{
    cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "my_subnet1"{
    vpc_id = aws_vpc.vpc1.id
    cidr_block = var.subnet1_cidr_block
}

resource "aws_instance" "web_server"{
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my_subnet1.id
}