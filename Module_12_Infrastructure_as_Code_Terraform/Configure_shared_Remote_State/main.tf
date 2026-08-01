# terraform {
#     required_version = ">= 0.12"
#     backend "s3" {
#         bucket = "terraform-remote-state-bucket"
#         key    = "terraform.tfstate"
#         region = "eu-central-1"
#         # availability_zone = "eu-central-1a"
#     }
# }

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

resource "aws_s3_bucket" "static_content_bucket" {
    region = var.region
    bucket = "my-static-content-bucket"
}

data "aws_iam_policy_document" "origin_bucket_policy"{
    statement{
        sid = "AllowCloudFrontServicePrincipalReadWrite"
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }
        actions = ["s3:GetObject", "s3:PutObject"]
        resources = ["${aws_s3_bucket.static_content_bucket.arn}/*"]

        condition {
            test = "StringEquals"
            variable = "AWS:SourceArn"
            values = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"]
        }
    }
}

resource "aws_s3_bucket_policy" "origin_bucket_policy" {
    bucket = aws__s3_bucket.static_content_bucket.id
    policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

data "aws_acm_certificate" "cert" {
    domain   = var.domain_name
    region = var.region
    statuses = ["ISSUED"]
}

resource "aws_cloudfront_origin_access_identity" "default"{
    name = "default-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
    origin {
        domain_name = aws_s3_bucket.static_content_bucket.bucket_regional_domain_name
        origin_access_control_id = aws_cloudfront_origin_access_identity.default.id
        origin_id = "S3-${aws_s3_bucket.static_content_bucket.id}"
    }

    enabled = true
    is_ipv6_enabled = true
    # comment
    default_root_object = "index.html"
    aliases = [var.domain_name]
    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "S3-${aws_s3_bucket.static_content_bucket.id}"

        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }
}

data "aws_route53_zone" "my_domain" {
    name = var.domain_name
}

resource "aws_route53_zone" "cloudfront"{
    for_each  = aws_cloudfront_distribution.s3_distribution.aliases
    zone_id = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = true
} 

