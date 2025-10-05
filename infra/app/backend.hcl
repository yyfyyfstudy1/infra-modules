# S3 Backend 配置
# 使用方法: terraform init -backend-config=backend.hcl

bucket         = "chime-mvp-tfstate-dev-syd"
key            = "app/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true

# 使用 Workspace 来区分环境
# terraform workspace select dev
# terraform workspace select test
# terraform workspace select prod