# Chime MVP - Terraform 基础设施代码

## 📁 项目结构

这个项目采用**单入口多环境**的设计模式，将业务应用和 CI/CD 基础设施完全分离：

```
infra-modules/
├── infra/
│   ├── app/                    # 📦 业务应用栈（单入口，多环境）
│   │   ├── main.tf            # 业务资源定义（Lambda、API Gateway、S3 等）
│   │   ├── variables.tf       # 变量定义
│   │   ├── providers.tf       # AWS Provider 配置
│   │   ├── outputs.tf         # 输出定义
│   │   ├── versions.tf        # Terraform 版本要求
│   │   ├── backend.hcl        # S3 后端配置（使用 Workspace）
│   │   ├── deploy.sh          # 🚀 部署脚本
│   │   └── envs/              # 各环境配置文件
│   │       ├── dev.tfvars     # Dev 环境变量
│   │       ├── test.tfvars    # Test 环境变量
│   │       └── prod.tfvars    # Prod 环境变量
│   │
│   ├── cicd-infra/            # 🔧 CI/CD 基础设施栈（独立入口）
│   │   ├── main.tf            # Jenkins 基础设施（VPC、EC2、ALB 等）
│   │   ├── variables.tf       # 变量定义
│   │   ├── providers.tf       # AWS Provider 配置
│   │   ├── outputs.tf         # 输出定义
│   │   ├── versions.tf        # Terraform 版本要求
│   │   ├── backend.hcl        # S3 后端配置（独立状态）
│   │   ├── terraform.tfvars   # CI/CD 配置
│   │   └── deploy.sh          # 🚀 部署脚本
│   │
│   └── modules/               # 🧩 可复用模块
│       ├── lambda_app/        # Lambda 函数模块
│       ├── apigw_http/        # API Gateway HTTP API 模块
│       ├── s3_bucket/         # S3 桶模块
│       ├── vpc/               # VPC 网络模块
│       ├── jenkins_ec2/       # Jenkins EC2 模块
│       └── jenkins_alb/       # Jenkins ALB 模块
│
├── cicd/                      # 📜 CI/CD 相关配置
│   ├── cross-account-roles/   # 跨账号 IAM 角色
│   ├── jenkins-pipelines/     # Jenkinsfile 模板
│   └── README.md
│
└── dist/                      # 📦 Lambda 部署包
    └── join.zip

```

## 🎯 设计理念

### 1. 单入口多环境（App Stack）
- **一份代码**：`infra/app/main.tf` 定义所有业务资源
- **多环境配置**：差异通过 `envs/{dev,test,prod}.tfvars` 管理
- **Workspace 隔离**：使用 Terraform Workspace 区分环境状态

### 2. 独立 CI/CD 基础设施（CICD Stack）
- **独立生命周期**：Jenkins 基础设施不受应用发布影响
- **单独状态管理**：独立的后端配置和状态文件
- **长期稳定**：升级、维护、备份独立进行

## 🚀 快速开始

### 前置要求

1. **Terraform** >= 1.5.0
2. **AWS CLI** 已配置好以下 Profile：
   - `dev-account`
   - `test-account`
   - `prod-account`
3. **Lambda 部署包**：确保 `dist/join.zip` 存在

### 部署业务应用（App Stack）

```bash
# 1. 进入 app 目录
cd infra/app

# 2. 初始化（首次运行）
terraform init -backend-config=backend.hcl

# 3. 部署到 Dev 环境
./deploy.sh dev plan    # 预览变更
./deploy.sh dev apply   # 应用变更

# 4. 部署到 Test 环境
./deploy.sh test plan
./deploy.sh test apply

# 5. 部署到 Prod 环境
./deploy.sh prod plan
./deploy.sh prod apply
```

### 部署 CI/CD 基础设施

```bash
# 1. 进入 cicd-infra 目录
cd infra/cicd-infra

# 2. 初始化（首次运行）
terraform init -backend-config=backend.hcl

# 3. 部署 Jenkins
./deploy.sh plan    # 预览变更
./deploy.sh apply   # 应用变更

# 4. 获取 Jenkins 初始密码
# 查看输出中的命令，使用 SSM Session Manager 连接
```

## 📊 Workspace 管理

业务应用使用 Workspace 来隔离环境：

```bash
# 查看当前 Workspace
terraform workspace show

# 列出所有 Workspace
terraform workspace list

# 切换 Workspace
terraform workspace select dev
terraform workspace select test
terraform workspace select prod

# 创建新 Workspace
terraform workspace new dev
```

## 🔄 环境提升流程

```bash
# 1. Dev 环境开发和测试
cd infra/app
./deploy.sh dev apply

# 2. 验证 Dev 环境无误后，提升到 Test
./deploy.sh test apply

# 3. Test 环境验证通过后，提升到 Prod
./deploy.sh prod apply
```

## 🗂️ 后端状态管理

### App Stack（使用 Workspace）
- **S3 Bucket**: `chime-mvp-tfstate-dev-syd`
- **状态文件路径**:
  - Dev: `env:/dev/app/terraform.tfstate`
  - Test: `env:/test/app/terraform.tfstate`
  - Prod: `env:/prod/app/terraform.tfstate`
- **DynamoDB 表**: `tfstate-lock-dev`

### CICD Stack（独立状态）
- **S3 Bucket**: `chime-mvp-tfstate-dev-syd`
- **状态文件路径**: `cicd-infra/terraform.tfstate`
- **DynamoDB 表**: `tfstate-lock-dev`

## 🛠️ 常用命令

### 应用栈操作

```bash
cd infra/app

# 查看当前环境状态
terraform workspace show
terraform state list

# 查看特定资源
terraform state show module.lambda_join.aws_lambda_function.this

# 查看输出
terraform output
terraform output api_invoke_url

# 销毁环境
./deploy.sh dev destroy
```

### CI/CD 基础设施操作

```bash
cd infra/cicd-infra

# 查看状态
terraform state list

# 查看输出
terraform output
terraform output jenkins_url

# 销毁 CI/CD 基础设施
./deploy.sh destroy
```

## 📝 配置说明

### 环境变量配置

每个环境的配置文件位于 `infra/app/envs/` 目录：

**`dev.tfvars`** - 开发环境
- 启用测试 S3 桶
- 较小的 Lambda 内存配置
- 使用 `dev-account` Profile

**`test.tfvars`** - 测试环境
- 禁用测试 S3 桶
- 中等资源配置
- 使用 `test-account` Profile

**`prod.tfvars`** - 生产环境
- 禁用测试 S3 桶
- 更大的 Lambda 内存和超时
- 使用 `prod-account` Profile

### CI/CD 配置

CI/CD 基础设施的配置在 `infra/cicd-infra/terraform.tfvars`：

- VPC 网络配置
- Jenkins EC2 实例类型和 EBS 大小
- 安全组和访问控制
- 跨账号 IAM 角色配置

## 🔐 安全最佳实践

1. **限制访问 IP**：修改 `allowed_cidr_blocks` 为公司出口 IP
2. **使用 HTTPS**：配置 ACM 证书 ARN
3. **最小权限原则**：Lambda 和 Jenkins IAM 角色仅授予必要权限
4. **状态文件加密**：S3 后端启用加密
5. **状态锁定**：使用 DynamoDB 防止并发修改

## 📚 资源说明

### App Stack 包含：
- Lambda 函数（Chime Join）
- API Gateway HTTP API
- IAM 角色和策略
- S3 测试桶（仅 Dev）

### CICD Stack 包含：
- VPC（公有/私有子网）
- NAT Gateway
- Jenkins EC2 实例
- EBS 数据卷
- Application Load Balancer
- 安全组
- IAM 角色（含跨账号 AssumeRole）

## 🆘 故障排查

### 问题 1: Workspace 不存在

```bash
# 创建新的 Workspace
terraform workspace new dev
```

### 问题 2: 后端未初始化

```bash
# 重新初始化后端
terraform init -backend-config=backend.hcl -reconfigure
```

### 问题 3: 状态锁定

```bash
# 强制解锁（谨慎使用）
terraform force-unlock <LOCK_ID>
```

### 问题 4: Lambda 部署包不存在

确保 `dist/join.zip` 文件存在，或修改 `tfvars` 文件中的 `lambda_zip_path`。

## 📞 获取帮助

- 查看 `infra/app/README.md` - 应用栈详细说明
- 查看 `infra/cicd-infra/README.md` - CI/CD 基础设施详细说明
- 查看 `cicd/README.md` - Jenkins 配置和使用指南

## 🎉 优势总结

✅ **单入口多环境** - 一份代码，多处运行  
✅ **独立生命周期** - App 和 CI/CD 互不干扰  
✅ **Workspace 隔离** - 环境状态完全独立  
✅ **配置集中管理** - 环境差异一目了然  
✅ **部署脚本简化** - 一键部署，轻松运维  
✅ **可扩展性强** - 轻松添加新环境或服务  

