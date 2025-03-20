provider "aws" {
  region = "eu-west-3"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_lambda_function" "my_lambda" {
  filename         = "../lambda.zip"  
  source_code_hash = filebase64sha256("../lambda.zip")
  function_name    = "myLambdaFunction"
  role            = aws_iam_role.lambda_exec.arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "ParisTimeAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.my_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "lambda_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /time"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

output "api_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/time"
}

