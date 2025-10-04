provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile  # 使用 dev-account profile
  
  default_tags {
    tags = local.common_tags
  }
}

