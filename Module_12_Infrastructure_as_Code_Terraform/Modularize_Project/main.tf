locals {
  common_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }, var.additional_tags)
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-vpc" })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-igw" })
}

module "subnet" {
  source = "./modules/subnet"

  vpc_id              = aws_vpc.main.id
  availability_zone   = data.aws_availability_zones.available.names[0]
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  tags                = local.common_tags
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-nat-eip" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = module.subnet.public_subnet_id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-nat" })
}

module "route_table" {
  source = "./modules/route_table"

  vpc_id              = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.main.id
  nat_gateway_id      = aws_nat_gateway.main.id
  public_subnet_id    = module.subnet.public_subnet_id
  private_subnet_id   = module.subnet.private_subnet_id
  tags                = local.common_tags
}

resource "aws_security_group" "public_instance" {
  name_prefix = "${var.project_name}-${var.environment}-public-"
  description = "Allow configured HTTP and SSH access to the public instance."
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from approved networks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_http_cidr_blocks
  }

  ingress {
    description = "SSH from administrator networks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-public-sg" })
}

resource "aws_security_group" "private_instance" {
  name_prefix = "${var.project_name}-${var.environment}-private-"
  description = "Allow SSH to the private instance only from the public instance."
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_instance.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-private-sg" })
}

resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = module.subnet.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.public_instance.id]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name

  user_data = <<-EOF
        #!/bin/bash
        set -euxo pipefail
        dnf update -y
        dnf install -y nginx
        systemctl enable --now nginx
    EOF

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-web-server" })
}

resource "aws_instance" "private_workload" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = module.subnet.private_subnet_id
  vpc_security_group_ids = [aws_security_group.private_instance.id]
  key_name               = var.key_pair_name

  tags = merge(local.common_tags, { Name = "${var.project_name}-${var.environment}-private-workload" })
}