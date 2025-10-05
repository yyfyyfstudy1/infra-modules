variable "bucket_name" {
  description = "S3 桶名称"
  type        = string
}

variable "versioning_enabled" {
  description = "是否启用版本控制"
  type        = bool
  default     = false
}

variable "force_destroy" {
  description = "是否允许强制删除非空桶"
  type        = bool
  default     = false
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

variable "block_public_acls" {
  description = "是否阻止公共 ACL"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "是否阻止公共策略"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "是否忽略公共 ACL"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "是否限制公共桶"
  type        = bool
  default     = true
}

