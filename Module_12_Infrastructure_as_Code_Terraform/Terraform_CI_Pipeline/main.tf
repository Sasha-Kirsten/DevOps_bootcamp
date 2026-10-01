/*
resource "aws_lambda_function" "serverless_lambda"{
    filename         = data.archive_file.lamdba.output_path
    function_name    = var.function_name
    role             = aws_iam_role.lambda.arn
    handler          = "lambda_function.lambda_handler"
    
    source_code_hash = data.archive_file.lamdba.output_base64sha256
    runtime = "python3.12" #index.mjs

    environment {
        variables = {
            ENVIRONMENT = var.environment
        }
    }

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-${var.environment}-lambda"
    })
}

resource "aws_iam_role" "lambda" {
    name_prefix        = "${var.project_name}-${var.environment}-lambda-"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

    tags = merge(local.common_tags, {
        Name = "${var.project_name}-${var.environment}-lambda-role"
    })
}

resource "aws_api_gateway_rest_api" "api" {
    name        = "${var.project_name}-${var.environment}-api"
    description = "Serverless API managed by Terraform."

    endpoint_configuration {
        types = ["REGIONAL"]
    }

    tags = local.common_tags
}

resource "aws_api_gateway_resource" "endpoint" {
    rest_api_id = aws_api_gateway_rest_api.api.id
    parent_id   = aws_api_gateway_rest_api.api.root_resource_id
    path_part   = var.api_path_part
}

resource "aws_api_gateway_method" "get" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    resource_id   = aws_api_gateway_resource.endpoint.id
    http_method   = "GET"
    authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
    rest_api_id             = aws_api_gateway_rest_api.api.id
    resource_id             = aws_api_gateway_resource.endpoint.id
    http_method             = aws_api_gateway_method.get.http_method
    integration_http_method = "POST"
    type                    = "AWS_PROXY"
    uri                     = aws_lambda_function.api.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
    statement_id  = "AllowExecutionFromAPIGateway"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.api.function_name
    principal     = "apigateway.amazonaws.com"
    source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/LEGACY-WILDCARD/${aws_api_gateway_method.get.http_method}${aws_api_gateway_resource.endpoint.path}"
}

resource "aws_api_gateway_deployment" "api" {
    rest_api_id = aws_api_gateway_rest_api.api.id

    triggers = {
        redeployment = sha1(jsonencode([
            aws_api_gateway_resource.endpoint.id,
            aws_api_gateway_method.get.id,
            aws_api_gateway_integration.lambda.id,
        ]))
    }

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_api_gateway_stage" "api" {
    rest_api_id   = aws_api_gateway_rest_api.api.id
    deployment_id = aws_api_gateway_deployment.api.id
    stage_name    = var.stage_name

    tags = local.common_tags
}

resource "aws_api_gateway_method_settings" "get" {
    rest_api_id = aws_api_gateway_rest_api.api.id
    stage_name  = aws_api_gateway_stage.api.stage_name
    method_path = "${aws_api_gateway_resource.endpoint.path_part}/${aws_api_gateway_method.get.http_method}"

    settings {
        throttling_rate_limit  = var.throttling_rate_limit
        throttling_burst_limit = var.throttling_burst_limit
        metrics_enabled        = true
    }
}
        }
    }
}

data "aws_iam_policy_document" "assume_role"{
    statement {
        effect = "Allow"

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
        actions = ["sts:AssumeRole"]
    }
}

resource "aws_lambda_permission" "apigw_lambda" {
    statement_id = "AllowExecutionFromAPIGateway"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.serverless_lambda.function_name
    principal = "apigateway.amazonaws.com"
    source_arn = "${var.execution_arn}/LEGACY-WILDCARD/${aws_api_gateway_method.api_method.http_method}/${aws_api_gateway_resource.api_resource.path}"
}

resource "aws_api_gateway_method_settings" "method_settings"{
    rest_api_id = var.api_gateway_id
    stage_name = var.stage_name
    method_path = "${aws_api_gateway_resource.api_resource.path}/${aws_api_gateway_method.api_method.http_method}"
    settings {
        throttling_rate_limit = 1000
        throttling_burst_limit = 200
    }
}

resource "aws_iam_role" "iam_lambda"{
    name = "iam_lambda"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lamdba" {
    type        = "zip"
    source_file = "${path.module}/lambda_function.py"
    output_path = "${path.module}/lambda_function_payload.zip"
}

module "get_data"{
    source = "./modules/lambda"
    name = "get_data"
}



resource "aws_api_gateway_rest_api" "api" {
  name = "my_serverless_api"
}

resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "my-endpoint"
}

resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_resource.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST" # Lambda requires POST for invocation
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.serverless_lambda.invoke_arn
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
*/
