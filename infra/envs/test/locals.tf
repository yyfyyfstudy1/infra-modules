locals {
  env         = "test"
  name_prefix = "${var.project_name}-${local.env}"
  
  common_tags = {
    Project     = var.project_name
    Environment = local.env
    ManagedBy   = "Terraform"
    Owner       = var.owner
  }
}

