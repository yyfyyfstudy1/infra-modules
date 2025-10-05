output "instance_id" {
  description = "Jenkins EC2 实例 ID"
  value       = aws_instance.jenkins.id
}

output "instance_private_ip" {
  description = "Jenkins EC2 私有 IP"
  value       = aws_instance.jenkins.private_ip
}

output "instance_role_arn" {
  description = "Jenkins IAM 角色 ARN"
  value       = aws_iam_role.jenkins.arn
}

output "instance_role_name" {
  description = "Jenkins IAM 角色名称"
  value       = aws_iam_role.jenkins.name
}

output "security_group_id" {
  description = "Jenkins 安全组 ID"
  value       = aws_security_group.jenkins.id
}

output "alb_security_group_id" {
  description = "ALB 安全组 ID"
  value       = aws_security_group.alb.id
}

output "ebs_volume_id" {
  description = "Jenkins 数据卷 ID"
  value       = aws_ebs_volume.jenkins.id
}

