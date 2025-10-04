# 🚀 快速开始指南

本指南将帮助你在 5 分钟内完成项目的部署。

## ✅ 前置检查

在开始之前，确保你已经：

- [ ] 安装 Terraform >= 1.5.0
- [ ] 配置好 AWS CLI Profile：`dev-account`、`test-account`、`prod-account`
- [ ] 准备好 Lambda 部署包：`dist/join.zip`
- [ ] 创建 S3 后端桶和 DynamoDB 表（仅首次）

## 📦 Step 1: 部署业务应用到 Dev 环境

```bash
# 进入 app 目录
cd infra/app

# 初始化 Terraform（首次运行）
terraform init -backend-config=backend.hcl

# 部署到 dev 环境
./deploy.sh dev plan
./deploy.sh dev apply

# 获取 API URL
terraform output api_invoke_url
```

**预期结果**:
```
api_invoke_url = "https://xxxxx.execute-api.ap-southeast-2.amazonaws.com/dev"
```

## 🧪 Step 2: 测试 Dev 环境

```bash
# 获取 API URL
API_URL=$(terraform output -raw api_invoke_url)

# 测试 API
curl -X POST "$API_URL/join" \
  -H "Content-Type: application/json" \
  -d '{"meetingId": "test-meeting"}'
```

## 🔄 Step 3: 提升到 Test 环境

```bash
# 仍然在 infra/app 目录

# 部署到 test 环境
./deploy.sh test plan
./deploy.sh test apply

# 获取 Test 环境的 API URL
terraform output api_invoke_url
```

## 🚀 Step 4: 提升到 Prod 环境

```bash
# 部署到 prod 环境
./deploy.sh prod plan
./deploy.sh prod apply

# 获取 Prod 环境的 API URL
terraform output api_invoke_url
```

## 🔧 Step 5: （可选）部署 CI/CD 基础设施

```bash
# 进入 cicd-infra 目录
cd ../cicd-infra

# 修改配置文件
vim terraform.tfvars
# 重要: 修改 test_account_id 和 prod_account_id

# 初始化
terraform init -backend-config=backend.hcl

# 部署 Jenkins
./deploy.sh plan
./deploy.sh apply

# 获取 Jenkins URL
terraform output jenkins_url
```

## 🎯 验证部署

### 检查 App Stack 资源

```bash
cd infra/app

# 切换到 dev workspace
terraform workspace select dev

# 列出所有资源
terraform state list

# 查看输出
terraform output
```

### 检查 CICD Stack 资源

```bash
cd infra/cicd-infra

# 列出所有资源
terraform state list

# 获取 Jenkins 访问信息
terraform output jenkins_url
terraform output jenkins_instance_id
```

## 🔑 访问 Jenkins（如果部署了 CI/CD）

```bash
cd infra/cicd-infra

# 1. 获取 Jenkins Instance ID
INSTANCE_ID=$(terraform output -raw jenkins_instance_id)

# 2. 使用 SSM Session Manager 连接
aws ssm start-session \
  --target $INSTANCE_ID \
  --profile dev-account \
  --region ap-southeast-2

# 3. 在 EC2 内获取初始密码
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## 📊 常用命令速查

### Workspace 操作

```bash
# 查看当前 workspace
terraform workspace show

# 列出所有 workspace
terraform workspace list

# 切换 workspace
terraform workspace select dev
```

### 查看资源

```bash
# 查看所有资源
terraform state list

# 查看输出
terraform output

# 查看特定输出（不带引号）
terraform output -raw api_invoke_url
```

### 销毁资源

```bash
# App Stack - 销毁特定环境
cd infra/app
./deploy.sh dev destroy

# CICD Stack - 销毁 Jenkins
cd infra/cicd-infra
./deploy.sh destroy
```

## 🆘 遇到问题？

### 问题 1: Workspace 不存在

```bash
# 创建新的 workspace
terraform workspace new dev
```

### 问题 2: S3 后端桶不存在

```bash
# 手动创建 S3 桶和 DynamoDB 表
aws s3api create-bucket \
  --bucket chime-mvp-tfstate-dev-syd \
  --region ap-southeast-2 \
  --create-bucket-configuration LocationConstraint=ap-southeast-2 \
  --profile dev-account

aws dynamodb create-table \
  --table-name tfstate-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-southeast-2 \
  --profile dev-account
```

### 问题 3: Lambda 部署包不存在

```bash
# 检查文件是否存在
ls -lh dist/join.zip

# 如果不存在，确保你的 .NET Lambda 项目已编译并打包
```

### 问题 4: AWS Profile 未配置

```bash
# 配置 AWS CLI Profile
aws configure --profile dev-account
aws configure --profile test-account
aws configure --profile prod-account

# 验证配置
aws sts get-caller-identity --profile dev-account
```

## 📚 下一步

- 📖 阅读 [主 README](README.md) 了解完整架构
- 🔧 查看 [App Stack README](infra/app/README.md) 了解应用配置
- 🚀 查看 [CICD README](infra/cicd-infra/README.md) 了解 Jenkins 配置
- 🎯 配置 [Jenkins Pipeline](cicd/README.md) 实现自动化部署

## 🎉 完成！

恭喜！你已经成功部署了 Chime MVP 项目。

- ✅ Dev 环境运行中
- ✅ Test 环境运行中
- ✅ Prod 环境运行中
- ✅ （可选）Jenkins CI/CD 运行中

现在你可以开始开发和部署你的应用了！

