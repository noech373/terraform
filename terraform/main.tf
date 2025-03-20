provider "aws" {
  region = "eu-west-3"
}

data "aws_iam_role" "existing_lambda_exec" {
  name = "lambda_execution_role"
}

resource "aws_iam_role" "lambda_exec" {
  count = length(data.aws_iam_role.existing_lambda_exec.id) > 0 ? 0 : 1

  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_basic_execution" {
  name       = "lambda_basic_execution"
  roles      = [aws_iam_role.lambda_exec[0].name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}  

resource "aws_lambda_function" "my_lambda" {
  filename         = "../lambda.zip"  
  source_code_hash = filebase64sha256("../lambda.zip")
  function_name    = "myLambdaFunction"
  role            = aws_iam_role.lambda_exec[0].arn
  handler         = "index.handler"
  runtime         = "nodejs18.x"
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "ParisTimeHousseinNoeAPI"
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

