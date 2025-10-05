variable "function_name" {
  description = "Lambda 函数名称"
  type        = string
}

variable "handler" {
  description = "Lambda 处理器"
  type        = string
}

variable "runtime" {
  description = "Lambda 运行时"
  type        = string
  default     = "dotnet8"
}

variable "architectures" {
  description = "Lambda 架构"
  type        = list(string)
  default     = ["arm64"]
}

variable "timeout" {
  description = "Lambda 超时时间（秒）"
  type        = number
  default     = 20
}

variable "memory_size" {
  description = "Lambda 内存大小（MB）"
  type        = number
  default     = 512
}

variable "lambda_zip_path" {
  description = "Lambda 部署包路径"
  type        = string
}

variable "env_vars" {
  description = "Lambda 环境变量"
  type        = map(string)
  default     = {}
}

variable "iam_policies" {
  description = "附加到 Lambda 角色的 IAM 策略 ARN 列表"
  type        = list(string)
  default     = []
}

variable "custom_policy_json" {
  description = "自定义 IAM 策略 JSON（可选）"
  type        = string
  default     = null
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

