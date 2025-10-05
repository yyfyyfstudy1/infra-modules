# API Gateway HTTP API
resource "aws_apigatewayv2_api" "http" {
  name          = var.api_name
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins     = var.cors_configuration.allow_origins
    allow_methods     = var.cors_configuration.allow_methods
    allow_headers     = var.cors_configuration.allow_headers
    allow_credentials = var.cors_configuration.allow_credentials
    max_age           = var.cors_configuration.max_age
  }

  tags = var.tags
}

# Lambda 集成
resource "aws_apigatewayv2_integration" "lambda" {
  for_each               = { for idx, route in var.routes : route.route_key => route }
  api_id                 = aws_apigatewayv2_api.http.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_arn
  payload_format_version = "2.0"
  integration_method     = "POST"
}

# 路由
resource "aws_apigatewayv2_route" "lambda" {
  for_each  = { for idx, route in var.routes : route.route_key => route }
  api_id    = aws_apigatewayv2_api.http.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
}

# Lambda 调用权限
resource "aws_lambda_permission" "apigw" {
  for_each      = { for idx, route in var.routes : route.route_key => route }
  statement_id  = "AllowInvokeFrom-${replace(each.key, "/[^a-zA-Z0-9]/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

# Stage
resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy
  tags        = var.tags
}

