output "lambda_function_name" {
  description = "Name of the deployed Lambda function."
  value       = aws_lambda_function.api.function_name
}

output "api_invoke_url" {
  description = "URL of the API Gateway endpoint."
  value       = "${aws_api_gateway_stage.api.invoke_url}${aws_api_gateway_resource.endpoint.path}"
}