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
}

variable "chime_client_region" {
  description = "Chime Meetings 客户端区域"
  type        = string
  default     = "us-east-1"
}

variable "media_region" {
  description = "会议媒体区域"
  type        = string
  default     = "ap-southeast-2"
}

variable "lambda_zip_path" {
  description = "Lambda 部署包路径"
  type        = string
}

variable "lambda_memory_size" {
  description = "Lambda 内存大小（MB）"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Lambda 超时时间（秒）"
  type        = number
  default     = 20
}

variable "enable_test_bucket" {
  description = "是否创建测试 S3 桶（仅 dev 环境）"
  type        = bool
  default     = false
}

