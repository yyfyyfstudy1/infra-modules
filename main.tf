terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }

  backend "s3" {
    bucket         = "chime-mvp-tfstate-prod-syd"
    key            = "global/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "tf-state-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  name = var.project_name
}

# -----------------------
# IAM role for Lambda
# -----------------------
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${local.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# 基础执行策略（日志）
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Chime Meetings 权限（不同账户可能需要 chime-sdk-meetings 命名空间）
data "aws_iam_policy_document" "chime_policy" {
  statement {
    effect = "Allow"
    actions = [
      "chime:CreateMeeting",
      "chime:CreateAttendee",
      "chime:GetMeeting",
      "chime:DeleteMeeting",
      "chime-sdk-meetings:CreateMeeting",
      "chime-sdk-meetings:CreateAttendee",
      "chime-sdk-meetings:GetMeeting",
      "chime-sdk-meetings:DeleteMeeting"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "chime" {
  name   = "${local.name}-chime"
  policy = data.aws_iam_policy_document.chime_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_chime" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.chime.arn
}

# -----------------------
# Lambda function
# -----------------------
resource "aws_lambda_function" "join" {
  function_name = "${local.name}-join"
  role          = aws_iam_role.lambda_role.arn
  filename      = var.lambda_zip_path
  handler       = "JoinFunction::JoinFunction.Function::FunctionHandler"
  runtime       = "dotnet8"
  architectures = ["arm64"] # 也可 x86_64

  environment {
    variables = {
      CHIME_CLIENT_REGION = var.chime_client_region
      MEDIA_REGION        = var.media_region
    }
  }

  timeout = 20
}

# -----------------------
# API Gateway HTTP API
# -----------------------
resource "aws_apigatewayv2_api" "http" {
  name          = "${local.name}-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS", "GET"]
    allow_headers     = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    allow_credentials = false
    max_age           = 86400
  }
}

resource "aws_apigatewayv2_integration" "join" {
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.join.invoke_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

resource "aws_apigatewayv2_route" "join" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /join"
  target    = "integrations/${aws_apigatewayv2_integration.join.id}"
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowInvokeFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.join.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "prod"
  auto_deploy = true
}



