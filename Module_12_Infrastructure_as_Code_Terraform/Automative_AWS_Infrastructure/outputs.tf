output "vpc_id" {
  description = "ID of the provisioned VPC."
  value       = aws_vpc.main.id
}

output "public_instance_id" {
  description = "ID of the public EC2 instance."
  value       = aws_instance.public.id
}

output "public_instance_public_ip" {
  description = "Public IP address of the web instance."
  value       = aws_instance.public.public_ip
}

output "private_instance_id" {
  description = "ID of the private EC2 instance."
  value       = aws_instance.private.id
}

output "web_url" {
  description = "HTTP URL for the NGINX page on the public instance."
  value       = "http://${aws_instance.public.public_dns}"
}