# CI/CD 环境的后端配置
# 使用方法: terraform init -backend-config=backend.hcl

bucket         = "chime-mvp-tfstate-dev-syd"
key            = "envs/cicd/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true

