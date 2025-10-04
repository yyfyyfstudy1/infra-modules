output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.http.id
}

output "api_endpoint" {
  description = "API Gateway 端点"
  value       = aws_apigatewayv2_api.http.api_endpoint
}

output "api_invoke_url" {
  description = "API Gateway 完整调用 URL"
  value       = "${aws_apigatewayv2_api.http.api_endpoint}/${aws_apigatewayv2_stage.this.name}"
}

output "stage_name" {
  description = "Stage 名称"
  value       = aws_apigatewayv2_stage.this.name
}

output "stage_arn" {
  description = "Stage ARN"
  value       = aws_apigatewayv2_stage.this.arn
}

