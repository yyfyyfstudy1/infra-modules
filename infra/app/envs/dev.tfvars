# Dev 环境变量配置
# 使用方法: 
#   terraform workspace select dev (或 terraform workspace new dev)
#   terraform plan -var-file=envs/dev.tfvars

project_name = "chime-mvp"
owner        = "platform-team"
aws_region   = "ap-southeast-2"
aws_profile  = "dev-account"

# Lambda 配置
lambda_zip_path    = "../../dist/join.zip"
lambda_memory_size = 512
lambda_timeout     = 20

# Chime 配置
chime_client_region = "us-east-1"
media_region        = "ap-southeast-2"

# 仅 dev 环境创建测试桶
enable_test_bucket = true

