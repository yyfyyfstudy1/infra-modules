# Prod 环境变量配置
# 使用方法: terraform plan -var-file=prod.tfvars

project_name    = "chime-mvp"
owner           = "platform-team"
aws_region      = "ap-southeast-2"

# Lambda 配置 - Prod 环境使用更高配置
lambda_zip_path    = "../../../dist/join.zip"
lambda_memory_size = 1024
lambda_timeout     = 30

# Chime 配置
chime_client_region = "us-east-1"
media_region        = "ap-southeast-2"

