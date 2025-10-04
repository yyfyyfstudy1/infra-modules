output "api_invoke_url" {
  description = "API Gateway 调用 URL"
  value       = module.api_gateway.api_invoke_url
}

output "lambda_function_name" {
  description = "Lambda 函数名称"
  value       = module.lambda_join.function_name
}

output "lambda_function_arn" {
  description = "Lambda 函数 ARN"
  value       = module.lambda_join.function_arn
}

