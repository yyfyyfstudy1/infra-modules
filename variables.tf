variable "project_name" {
  description = "项目名称，用于资源命名"
  type        = string
  default     = "chime-mvp"
}

variable "aws_region" {
  description = "AWS 主区域（Lambda、API Gateway、S3 部署区域）"
  type        = string
  default     = "ap-southeast-2"
}

variable "chime_client_region" {
  description = "Chime Meetings 客户端区域（通常为 us-east-1）"
  type        = string
  default     = "us-east-1"
}

variable "media_region" {
  description = "会议媒体区域（就近选择）"
  type        = string
  default     = "ap-southeast-2"
}

variable "lambda_zip_path" {
  description = "Lambda 部署包的路径"
  type        = string
  default     = "../dist/join.zip"
}
