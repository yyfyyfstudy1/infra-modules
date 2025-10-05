# Prod 环境变量配置
# 使用方法: 
#   terraform workspace select prod (或 terraform workspace new prod)
#   terraform plan -var-file=envs/prod.tfvars

project_name = "chime-mvp"
owner        = "platform-team"
aws_region   = "ap-southeast-2"
aws_profile  = "prod-account"

# Lambda 配置
lambda_zip_path    = "../../dist/join.zip"
lambda_memory_size = 1024  # 生产环境使用更大内存
lambda_timeout     = 30    # 生产环境更长超时

# Chime 配置
chime_client_region = "us-east-1"
media_region        = "ap-southeast-2"

# Prod 环境不创建测试桶
enable_test_bucket = false

