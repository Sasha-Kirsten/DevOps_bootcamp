resource "aws_vpc" "main"{
    name = var.vpc_name
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        name = var.vpc_name
    }

}


resource "aws_subnet" "public"{
    vpc_id = aws_vpc.main.id 
    cidr_block = var.public_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.vpc_name}-public-subnet"
    }
}

resource "aws_subnet" "private"{
    vpc_id = aws_vpc.main.id 
    cidr_block = var.private_subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = false
    tags = {
        Name = "${var.vpc_name}-private-subnet"
    }
}

resource "aws_internet_gateway" "main"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.vpc_name}-igw"
    }
}

resource "aws_nat_gateway" "main"{
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public.id
    tags = {
        Name = "${var.vpc_name}-nat-gateway"
    }
}


resource "aws_ec2_instance" "web" {
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
        Name = "${var.vpc_name}-web-instance"
    }
}

