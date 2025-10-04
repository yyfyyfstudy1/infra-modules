output "role_arn" {
  description = "创建的 Jenkins 部署角色 ARN"
  value       = aws_iam_role.jenkins_deployer.arn
}

output "role_name" {
  description = "角色名称"
  value       = aws_iam_role.jenkins_deployer.name
}


