variable "name_prefix" {
  description = "VPC 命名前缀"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 块"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "公有子网 CIDR 列表"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "私有子网 CIDR 列表"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "availability_zones" {
  description = "可用区列表"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "是否启用 NAT Gateway"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "是否只使用单个 NAT Gateway（节省成本）"
  type        = bool
  default     = true
}

variable "tags" {
  description = "资源标签"
  type        = map(string)
  default     = {}
}

