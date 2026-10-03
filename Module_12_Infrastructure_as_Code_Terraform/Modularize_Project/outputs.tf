output "vpc_id" {
  description = "ID of the VPC created by the root module."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet created by the subnet module."
  value       = module.subnet.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet created by the subnet module."
  value       = module.subnet.private_subnet_id
}

output "web_server_public_ip" {
  description = "Public IP address of the NGINX web server."
  value       = aws_instance.web_server.public_ip
}

output "web_url" {
  description = "HTTP URL for the public NGINX web server."
  value       = "http://${aws_instance.web_server.public_dns}"
}
