output "ec2_public_ip" {
  description = "Public IPv4 address of the application host."
  value       = aws_instance.web.public_ip
}

output "application_url" {
  description = "HTTP endpoint for the deployed application."
  value       = "http://${aws_instance.web.public_dns}:${var.application_port}"
}