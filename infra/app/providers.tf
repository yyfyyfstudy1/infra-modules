provider "aws" {
  region = var.aws_region
  # profile = var.aws_profile  # 在 Jenkins 环境中使用 IAM Role，不需要 profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

