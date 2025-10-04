variable "api_name" {
  description = "API Gateway 名称"
  type        = string
}

variable "cors_configuration" {
  description = "CORS 配置"
  type = object({
    allow_origins     = list(string)
    allow_methods     = list(string)
    allow_headers     = list(string)
    allow_credentials = bool
    max_age           = number
  })
  default = {
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS", "GET"]
    allow_headers     = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    allow_credentials = false
    max_age           = 86400
  }
}

variable "routes" {
  description = "API 路由配置列表"
  type = list(object({
    route_key       = string
    lambda_arn      = string
    lambda_name     = string
  }))
}

variable "stage_name" {
  description = "API Gateway Stage 名称"
  type        = string
  default     = "prod"
}

variable "auto_deploy" {
  description = "是否自动部署"
  type        = bool
  default     = true
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

