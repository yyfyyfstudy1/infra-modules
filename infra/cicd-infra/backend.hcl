# S3 Backend 配置 - CICD 基础设施
# 使用方法: terraform init -backend-config=backend.hcl

bucket         = "chime-mvp-tfstate-dev-syd"
key            = "cicd-infra/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true

# CICD 基础设施独立管理，不使用 Workspace

