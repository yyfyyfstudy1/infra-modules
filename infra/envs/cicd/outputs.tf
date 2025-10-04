output "jenkins_url" {
  description = "Jenkins 访问 URL"
  value       = module.jenkins_alb.jenkins_url
}

output "jenkins_alb_dns" {
  description = "Jenkins ALB DNS 名称"
  value       = module.jenkins_alb.alb_dns_name
}

output "jenkins_instance_id" {
  description = "Jenkins EC2 实例 ID"
  value       = module.jenkins_ec2.instance_id
}

output "jenkins_instance_private_ip" {
  description = "Jenkins EC2 私有 IP"
  value       = module.jenkins_ec2.instance_private_ip
}

output "jenkins_role_arn" {
  description = "Jenkins IAM 角色 ARN"
  value       = module.jenkins_ec2.instance_role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "initial_admin_password_command" {
  description = "获取 Jenkins 初始密码的命令"
  value       = "aws ssm start-session --target ${module.jenkins_ec2.instance_id} --profile ${var.aws_profile} --region ${var.aws_region}"
}

output "jenkins_target_group_arn" {
  description = "Jenkins 目标组 ARN"
  value       = module.jenkins_alb.target_group_arn
}

output "jenkins_alb_arn" {
  description = "Jenkins ALB ARN"
  value       = module.jenkins_alb.alb_arn
}

