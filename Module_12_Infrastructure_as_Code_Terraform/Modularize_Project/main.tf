provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

module "subnet" {
    source = "./modules/subnet"
    public_sg = aws_security_group.public_sg.name
    private_sg = aws_security_group.private_sg.name
    public_sg_ingress_port = var.public_sg_ingress_port
    private_sg_ingress_port = var.private_sg_ingress_port
    public_subnet1 = var.public_subnet1
    private_subnet1 = var.private_subnet1
}

resource "aws_vpc" "vpc1"{
    cidr_block = "10.0.0.0.0.0/16"
}

# resource "aws_subnet" "public_subnet1" {
#     vpc_id = aws_vpc.vpc1.id
#     cidr_block = "10.0.1.0/24"
# }



resource "aws_instance" "web_server"{
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    public_subnet_id = module.subnet.public_subnet1_id
    security_groups = [module.subnet.public_sg_id]
    private_subnet_id = module.subnet.private_subnet1_id
}

resource "aws_security_group" "public_sg" {
    vpc_id = aws_vpc.vpc1.id
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}