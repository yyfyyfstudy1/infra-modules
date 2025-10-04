output "api_invoke_url" {
  description = "API Gateway 调用 URL"
  value       = "${aws_apigatewayv2_api.http.api_endpoint}/${aws_apigatewayv2_stage.prod.name}"
}


output "lambda_function_name" {
  description = "Lambda 函数名称"
  value       = aws_lambda_function.join.function_name
}

output "lambda_function_arn" {
  description = "Lambda 函数 ARN"
  value       = aws_lambda_function.join.arn
}


