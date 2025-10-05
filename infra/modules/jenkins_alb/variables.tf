variable "name_prefix" {
  description = "资源命名前缀"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "ALB 子网 ID 列表（至少2个）"
  type        = list(string)
}

variable "security_group_id" {
  description = "ALB 安全组 ID"
  type        = string
}

variable "target_id" {
  description = "目标实例 ID"
  type        = string
}

variable "certificate_arn" {
  description = "ACM 证书 ARN（可选，用于 HTTPS）"
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "健康检查路径"
  type        = string
  default     = "/login"
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

