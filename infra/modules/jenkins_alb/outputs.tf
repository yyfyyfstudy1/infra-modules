output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.jenkins.arn
}

output "alb_dns_name" {
  description = "ALB DNS 名称"
  value       = aws_lb.jenkins.dns_name
}

output "alb_zone_id" {
  description = "ALB Route53 Zone ID"
  value       = aws_lb.jenkins.zone_id
}

output "target_group_arn" {
  description = "目标组 ARN"
  value       = aws_lb_target_group.jenkins.arn
}

output "http_listener_arn" {
  description = "HTTP 监听器 ARN"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "HTTPS 监听器 ARN（如果配置了）"
  value       = var.certificate_arn != "" ? aws_lb_listener.https[0].arn : null
}

output "jenkins_url" {
  description = "Jenkins 访问 URL"
  value       = var.certificate_arn != "" ? "https://${aws_lb.jenkins.dns_name}" : "http://${aws_lb.jenkins.dns_name}"
}

