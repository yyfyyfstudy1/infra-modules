output "function_name" {
  description = "Lambda 函数名称"
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "Lambda 函数 ARN"
  value       = aws_lambda_function.this.arn
}

output "invoke_arn" {
  description = "Lambda 函数调用 ARN"
  value       = aws_lambda_function.this.invoke_arn
}

output "role_arn" {
  description = "Lambda IAM 角色 ARN"
  value       = aws_iam_role.lambda_role.arn
}

output "role_name" {
  description = "Lambda IAM 角色名称"
  value       = aws_iam_role.lambda_role.name
}

