provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # 使用本地 AWS CLI profile
  
  default_tags {
    tags = local.common_tags
  }
}

