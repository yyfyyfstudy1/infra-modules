variable "name_prefix" {
  description = "资源命名前缀"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "EC2 实例所在的子网 ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 实例类型"
  type        = string
  default     = "t3.large"
}

variable "ebs_volume_size" {
  description = "EBS 卷大小（GB）"
  type        = number
  default     = 100
}

variable "allowed_cidr_blocks" {
  description = "允许访问 Jenkins 的 CIDR 块列表"
  type        = list(string)
}

variable "test_account_id" {
  description = "Test 账户 ID"
  type        = string
}

variable "prod_account_id" {
  description = "Prod 账户 ID"
  type        = string
}

variable "key_name" {
  description = "EC2 密钥对名称（可选）"
  type        = string
  default     = ""
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

