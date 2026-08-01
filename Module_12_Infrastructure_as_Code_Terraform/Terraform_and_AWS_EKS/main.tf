provider "aws" {
  region = "eu-central-1"
}

data "aws_availability_zones" "azs" {
#   state = "available"
    names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}


resource "aws_vpc" "vpc1" {
    cidr_block = var.cidr_block

    private_subnet = var.private_subnet

    public_subnet = var.public_subnet
    # azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    azs = data.aws_availability_zones.azs.names 
    enable_dns_support = true
    enable_dns_hostnames = true
    single_dns_gateway = true
    tags = {
        Name = "my-vpc"
    }
}

