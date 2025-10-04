locals {
  env         = "cicd"
  name_prefix = "${var.project_name}-${local.env}"
  
  common_tags = {
    Project     = var.project_name
    Environment = local.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
    Purpose     = "Jenkins-CICD"
  }
  
  # 获取可用区
  azs = data.aws_availability_zones.available.names
}

# 获取可用区数据
data "aws_availability_zones" "available" {
  state = "available"
}

# 获取 test 和 prod 账户 ID
data "aws_caller_identity" "current" {}

