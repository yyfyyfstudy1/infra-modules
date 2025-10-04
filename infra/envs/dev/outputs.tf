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

output "test_bucket_name" {
  description = "测试 S3 桶名称"
  value       = module.test_bucket.bucket_id
}

output "test_bucket_arn" {
  description = "测试 S3 桶 ARN"
  value       = module.test_bucket.bucket_arn
}

output "test_cicd_bucket_name" {
  description = "CI/CD 测试 S3 桶名称"
  value       = module.test_cicd_bucket.bucket_id
}

output "test_cicd_bucket_arn" {
  description = "CI/CD 测试 S3 桶 ARN"
  value       = module.test_cicd_bucket.bucket_arn
}

