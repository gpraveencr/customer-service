
# terraform {
#   required_version = ">= 0.14.0"

#   cloud {
#     organization = "example-org-d4d6b5"

#     workspaces {
#       name = "customer-api-sandbox--aws-us-east-2"
#     }
#   }
# }

provider "aws" {
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
  region     = "us-east-2"
}

resource "aws_lambda_function" "GetCustomers" {
  filename      = "terraform-lambda-java-1.0-SNAPSHOT.jar"
  function_name = "GetCustomers"
  role          = aws_iam_role.execute-lambda.arn
  handler       = "handler.LambdaHandler"
  runtime       = "java8"
}

resource "aws_apigatewayv2_api" "customer-api-gateway" {
  name          = "customer-api-gateway"
  protocol_type = "HTTP"
  target        = aws_lambda_function.GetCustomers.arn
}

resource "aws_lambda_permission" "api-gateway-permissions" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.GetCustomers.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.customer-api-gateway.execution_arn}/*/*"
}

resource "aws_iam_role" "execute-lambda" {
  name = "execute-lambda"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}
