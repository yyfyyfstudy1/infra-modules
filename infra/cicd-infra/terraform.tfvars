# CI/CD 基础设施配置
# 使用方法: terraform plan (会自动加载此文件)
#          或: terraform plan -var-file=terraform.tfvars

project_name = "chime-mvp"
owner        = "platform-team"
aws_region   = "ap-southeast-2"
aws_profile  = "dev-account"

# VPC 配置
vpc_cidr = "10.0.0.0/16"

# Jenkins 配置
jenkins_instance_type = "t3.large"
jenkins_ebs_size      = 100
jenkins_key_name      = ""  # 如果有 SSH 密钥对，填写名称

# 安全配置 - 改为你公司的出口 IP
allowed_cidr_blocks = ["0.0.0.0/0"]  # ⚠️ 生产环境请限制为公司 IP

# ACM 证书（可选，如果有域名和证书）
acm_certificate_arn = ""

