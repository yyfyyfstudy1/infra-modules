terraform {
  backend "s3" {} # 使用 init -backend-config=backend.hcl 注入参数
}

# 本地变量
locals {
  env         = "cicd"
  name_prefix = "${var.project_name}-${local.env}"
  
  common_tags = {
    Environment = local.env
    Project     = var.project_name
    Owner       = var.owner
    ManagedBy   = "Terraform"
    Purpose     = "Jenkins-CICD"
  }
}

# 获取可用区
data "aws_availability_zones" "available" {
  state = "available"
}

# 获取当前 AWS 账户信息
data "aws_caller_identity" "current" {}

# 本地变量 - 可用区
locals {
  azs = data.aws_availability_zones.available.names
}

# VPC 模块
module "vpc" {
  source = "../modules/vpc"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(local.azs, 0, 2)  # 使用前2个可用区
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # 单个 NAT Gateway 节省成本

  tags = local.common_tags
}

# Jenkins EC2 模块
module "jenkins_ec2" {
  source = "../modules/jenkins_ec2"

  name_prefix         = local.name_prefix
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.private_subnet_ids[0]  # 放在私有子网
  instance_type       = var.jenkins_instance_type
  ebs_volume_size     = var.jenkins_ebs_size
  allowed_cidr_blocks = var.allowed_cidr_blocks
  key_name            = var.jenkins_key_name

  tags = local.common_tags

  depends_on = [module.vpc]
}

# Jenkins ALB 模块
module "jenkins_alb" {
  source = "../modules/jenkins_alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids  # ALB 放在公有子网
  security_group_id = module.jenkins_ec2.alb_security_group_id
  target_id         = module.jenkins_ec2.instance_id
  certificate_arn   = var.acm_certificate_arn
  health_check_path = "/login"

  tags = local.common_tags

  depends_on = [module.jenkins_ec2]
}

