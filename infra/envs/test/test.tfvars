# Test 环境变量配置
# 使用方法: terraform plan -var-file=test.tfvars

project_name    = "chime-mvp"
owner           = "platform-team"
aws_region      = "ap-southeast-2"

# Lambda 配置
lambda_zip_path    = "../../../dist/join.zip"
lambda_memory_size = 512
lambda_timeout     = 20

# Chime 配置
chime_client_region = "us-east-1"
media_region        = "ap-southeast-2"

