# App Stack - 业务应用基础设施

## 📖 概述

这是 Chime MVP 项目的业务应用层，采用**单入口多环境**设计模式。所有环境（dev、test、prod）使用同一份 Terraform 代码，通过 Terraform Workspace 和环境变量文件（tfvars）来区分配置差异。

## 🏗️ 架构

### 资源组成
- **Lambda 函数**: Chime Join 功能（.NET 8 Runtime）
- **API Gateway**: HTTP API，提供 RESTful 接口
- **IAM 角色**: Lambda 执行角色，包含 Chime SDK 权限
- **S3 桶**: 测试用桶（仅 dev 环境）

### 环境隔离
- 使用 **Terraform Workspace** 实现环境隔离
- 每个环境的状态文件独立存储在 S3
- 通过 `-var-file` 参数加载不同环境的配置

## 🚀 部署指南

### 首次部署

```bash
# 1. 初始化 Terraform
terraform init -backend-config=backend.hcl

# 2. 创建并切换到 dev workspace
terraform workspace new dev

# 3. 部署到 dev 环境
./deploy.sh dev plan
./deploy.sh dev apply
```

### 环境提升

```bash
# Dev -> Test
terraform workspace new test  # 首次
./deploy.sh test plan
./deploy.sh test apply

# Test -> Prod
terraform workspace new prod  # 首次
./deploy.sh prod plan
./deploy.sh prod apply
```

### 使用部署脚本

部署脚本 `deploy.sh` 会自动处理 Workspace 切换：

```bash
# 语法
./deploy.sh <环境> <操作>

# 示例
./deploy.sh dev plan      # 预览 dev 环境变更
./deploy.sh dev apply     # 应用 dev 环境变更
./deploy.sh test plan     # 预览 test 环境变更
./deploy.sh prod apply    # 应用 prod 环境变更
./deploy.sh dev destroy   # 销毁 dev 环境
```

## 📝 配置文件

### `envs/dev.tfvars`
```hcl
aws_profile        = "dev-account"
lambda_memory_size = 512
lambda_timeout     = 20
enable_test_bucket = true   # 仅 dev 环境创建测试桶
```

### `envs/test.tfvars`
```hcl
aws_profile        = "test-account"
lambda_memory_size = 512
lambda_timeout     = 20
enable_test_bucket = false
```

### `envs/prod.tfvars`
```hcl
aws_profile        = "prod-account"
lambda_memory_size = 1024   # 生产环境更大内存
lambda_timeout     = 30     # 生产环境更长超时
enable_test_bucket = false
```

## 🔧 手动操作

如果不使用部署脚本，可以手动执行：

```bash
# 初始化
terraform init -backend-config=backend.hcl

# 切换/创建 workspace
terraform workspace select dev  # 如果已存在
# 或
terraform workspace new dev     # 如果不存在

# 执行计划
terraform plan -var-file=envs/dev.tfvars -out=dev.tfplan

# 应用变更
terraform apply dev.tfplan

# 销毁资源
terraform destroy -var-file=envs/dev.tfvars
```

## 📊 Workspace 管理

### 查看当前 Workspace
```bash
terraform workspace show
```

### 列出所有 Workspace
```bash
terraform workspace list
```

### 切换 Workspace
```bash
terraform workspace select dev
terraform workspace select test
terraform workspace select prod
```

### 删除 Workspace
```bash
# 必须先切换到其他 workspace
terraform workspace select default
terraform workspace delete dev
```

## 🗂️ 状态管理

### 后端配置（backend.hcl）
```hcl
bucket         = "chime-mvp-tfstate-dev-syd"
key            = "app/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true
```

### 状态文件路径
使用 Workspace 后，实际的状态文件路径会自动添加前缀：
- Dev: `s3://chime-mvp-tfstate-dev-syd/env:/dev/app/terraform.tfstate`
- Test: `s3://chime-mvp-tfstate-dev-syd/env:/test/app/terraform.tfstate`
- Prod: `s3://chime-mvp-tfstate-dev-syd/env:/prod/app/terraform.tfstate`

### 查看状态
```bash
# 列出所有资源
terraform state list

# 查看特定资源
terraform state show module.lambda_join.aws_lambda_function.this
terraform state show module.api_gateway.aws_apigatewayv2_api.http

# 查看输出
terraform output
terraform output -json
terraform output api_invoke_url
```

## 🔄 环境变量

Terraform 会从以下来源读取变量（优先级从高到低）：
1. 命令行 `-var` 参数
2. `-var-file` 指定的文件
3. `terraform.tfvars` 文件（自动加载）
4. `*.auto.tfvars` 文件（自动加载）
5. 环境变量 `TF_VAR_name`
6. `variables.tf` 中的默认值

在本项目中，我们使用 `-var-file=envs/<env>.tfvars` 来指定环境配置。

## 🧪 测试部署

### 测试 Lambda 函数
```bash
# 获取 API URL
API_URL=$(terraform output -raw api_invoke_url)

# 测试 Join 端点
curl -X POST "$API_URL/join" \
  -H "Content-Type: application/json" \
  -d '{"meetingId": "test-meeting"}'
```

### 验证资源创建
```bash
# 查看 Lambda 函数
aws lambda get-function --function-name chime-mvp-dev-join --profile dev-account

# 查看 API Gateway
aws apigatewayv2 get-apis --profile dev-account | grep chime-mvp-dev

# 查看 S3 桶（仅 dev）
aws s3 ls | grep chime-mvp-dev-test-bucket
```

## 🛠️ 常用命令

```bash
# 格式化代码
terraform fmt -recursive

# 验证配置
terraform validate

# 查看执行计划（不应用）
terraform plan -var-file=envs/dev.tfvars

# 刷新状态（从 AWS 读取最新状态）
terraform refresh -var-file=envs/dev.tfvars

# 导入已存在的资源
terraform import -var-file=envs/dev.tfvars \
  module.lambda_join.aws_lambda_function.this \
  chime-mvp-dev-join
```

## 📈 扩展指南

### 添加新环境
```bash
# 1. 创建新的 tfvars 文件
cp envs/dev.tfvars envs/staging.tfvars

# 2. 修改配置
vim envs/staging.tfvars

# 3. 创建 workspace
terraform workspace new staging

# 4. 部署
./deploy.sh staging apply
```

### 添加新资源
在 `main.tf` 中添加新的模块调用，例如添加 SQS 队列：

```hcl
module "message_queue" {
  source = "../modules/sqs_queue"

  queue_name = "${local.name_prefix}-messages"
  tags       = local.common_tags
}
```

## 🆘 故障排查

### 问题 1: Workspace 冲突
```
Error: Workspace "dev" already exists
```
**解决**: 使用 `terraform workspace select dev` 而不是 `new`

### 问题 2: 状态锁定
```
Error: Error acquiring the state lock
```
**解决**: 
```bash
# 等待其他操作完成，或强制解锁（谨慎！）
terraform force-unlock <LOCK_ID>
```

### 问题 3: Lambda 部署包路径错误
```
Error: error creating Lambda Function: InvalidParameterValueException
```
**解决**: 检查 `lambda_zip_path` 是否正确指向 `dist/join.zip`

### 问题 4: Profile 未配置
```
Error: error configuring Terraform AWS Provider
```
**解决**: 确保 AWS CLI Profile 已正确配置
```bash
aws configure --profile dev-account
aws sts get-caller-identity --profile dev-account
```

## 📞 相关文档

- [主 README](../../README.md) - 项目总览
- [模块文档](../modules/README.md) - 可复用模块说明
- [CI/CD 文档](../cicd-infra/README.md) - Jenkins 基础设施
- [Jenkins 配置](../../cicd/README.md) - Jenkins 使用指南

