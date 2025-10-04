variable "project_name" {
  description = "项目名称"
  type        = string
  default     = "chime-mvp"
}

variable "owner" {
  description = "项目负责人或团队"
  type        = string
  default     = "platform-team"
}

variable "aws_region" {
  description = "AWS 部署区域"
  type        = string
  default     = "ap-southeast-2"
}

variable "aws_profile" {
  description = "AWS CLI Profile 名称"
  type        = string
  default     = "dev-account"
}

# VPC 配置
variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

# Jenkins EC2 配置
variable "jenkins_instance_type" {
  description = "Jenkins EC2 实例类型"
  type        = string
  default     = "t3.large"
}

variable "jenkins_ebs_size" {
  description = "Jenkins EBS 卷大小（GB）"
  type        = number
  default     = 100
}

variable "jenkins_key_name" {
  description = "EC2 SSH 密钥对名称（可选）"
  type        = string
  default     = ""
}

# 安全配置
variable "allowed_cidr_blocks" {
  description = "允许访问 Jenkins 的 CIDR 块列表（公司出口 IP）"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # 改为你的公司 IP
}

# ACM 证书（可选）
variable "acm_certificate_arn" {
  description = "ACM 证书 ARN（用于 HTTPS，可选）"
  type        = string
  default     = ""
}

# 跨账号配置
variable "test_account_id" {
  description = "Test 账户 ID"
  type        = string
}

variable "prod_account_id" {
  description = "Prod 账户 ID"
  type        = string
}

