# 快速开始指南

## ✅ 已完成配置

### Backend 配置（所有环境）
- ✅ Dev: S3 bucket + DynamoDB 表已创建并配置
- ✅ Test: S3 bucket + DynamoDB 表已创建并配置
- ✅ Prod: S3 bucket + DynamoDB 表已创建并配置
- ✅ 已启用版本控制、加密和公共访问阻止

### 资源验证
- ✅ 已成功在 dev 环境创建测试 S3 bucket：`chime-mvp-dev-test-bucket`
- ✅ State 文件已上传到 S3 并正常工作

## 📁 新的项目结构

```
infra-modules/
└── infra/
    ├── modules/              # 可复用模块层
    │   ├── lambda_app/       # Lambda 函数 + IAM 角色 + 权限
    │   ├── apigw_http/       # API Gateway HTTP API + 路由 + 集成
    │   └── s3_bucket/        # S3 桶 + 安全配置
    └── envs/                 # 环境落地层
        ├── dev/              # 开发环境（使用 dev-account profile）
        ├── test/             # 测试环境（使用 test-account profile）
        └── prod/             # 生产环境（使用 prod-account profile）
```

## 🚀 部署步骤

### 1. Dev 环境（✅ Backend 已配置）

```bash
cd infra/envs/dev

# 方法一：使用辅助脚本（推荐）
./tf.sh init
./tf.sh plan
./tf.sh apply

# 方法二：手动指定 AWS Profile
AWS_PROFILE=dev-account terraform init -backend-config=backend.hcl
AWS_PROFILE=dev-account terraform plan -var-file=dev.tfvars
AWS_PROFILE=dev-account terraform apply -var-file=dev.tfvars
```

### 2. Test 环境（✅ Backend 已配置）

```bash
cd infra/envs/test

# 使用辅助脚本
./tf.sh init
./tf.sh plan
./tf.sh apply

# 或手动指定 Profile
AWS_PROFILE=test-account terraform init -backend-config=backend.hcl
AWS_PROFILE=test-account terraform plan -var-file=test.tfvars
AWS_PROFILE=test-account terraform apply -var-file=test.tfvars
```

### 3. Prod 环境（✅ Backend 已配置）

```bash
cd infra/envs/prod

# 使用辅助脚本
./tf.sh init
./tf.sh plan
./tf.sh apply

# 或手动指定 Profile
AWS_PROFILE=prod-account terraform init -backend-config=backend.hcl
AWS_PROFILE=prod-account terraform plan -var-file=prod.tfvars
AWS_PROFILE=prod-account terraform apply -var-file=prod.tfvars
```

## 📋 前置条件检查

### 1. AWS CLI Profiles 已配置

```bash
aws configure list-profiles
# 应该看到：
# - dev-account
# - test-account
# - prod-account
```

### 2. Lambda 部署包准备

确保存在：`dist/join.zip`

如果没有，需要先构建你的 Lambda 函数代码。

### 3. 远端 Backend（✅ 已完成）

所有环境的远端 state 已配置完成：

| 环境 | S3 Bucket | DynamoDB 表 | 状态 |
|------|-----------|-------------|------|
| Dev | chime-mvp-tfstate-dev-syd | tfstate-lock-dev | ✅ 已配置 |
| Test | chime-mvp-tfstate-test-syd | tfstate-lock-test | ✅ 已配置 |
| Prod | chime-mvp-tfstate-prod-syd | tfstate-lock-prod | ✅ 已配置 |

**Backend 安全特性：**
- ✅ S3 版本控制已启用（可恢复历史 state）
- ✅ 服务端加密已启用（AES256）
- ✅ 公共访问已阻止
- ✅ DynamoDB 锁表已启用（防止并发冲突）

## 🔧 环境配置说明

### Dev 环境特点
- **Profile**: `dev-account`
- **Lambda 内存**: 512 MB
- **Lambda 超时**: 20 秒
- **测试用 S3 bucket**: 已启用（force_destroy=true）
- **用途**: 开发和测试

### Test 环境特点
- **Profile**: `test-account`
- **Lambda 内存**: 512 MB
- **Lambda 超时**: 20 秒
- **用途**: 集成测试和 QA

### Prod 环境特点
- **Profile**: `prod-account`
- **Lambda 内存**: 1024 MB（更高配置）
- **Lambda 超时**: 30 秒（更长时间）
- **CORS**: 建议限制具体域名
- **用途**: 生产环境

## 📝 常见任务

### 查看资源输出

```bash
cd infra/envs/dev
terraform output
```

### 更新 Lambda 代码

```bash
# 1. 构建新的部署包
# ... 生成 dist/join.zip

# 2. 应用更新
cd infra/envs/dev
terraform apply -var-file=dev.tfvars
```

### 清理测试资源

```bash
cd infra/envs/dev
terraform destroy -var-file=dev.tfvars
```

### 只清理测试 S3 bucket

```bash
cd infra/envs/dev
terraform destroy -var-file=dev.tfvars -target=module.test_bucket
```

## 🎯 下一步

1. **创建远端 backend**（如果还没有）
2. **准备 Lambda 部署包**（`dist/join.zip`）
3. **完整部署到 dev 环境**
4. **测试 API Gateway 端点**
5. **逐步推进到 test 和 prod 环境**

## 📚 详细文档

更多信息请查看：`infra/README.md`

## ⚠️ 注意事项

1. **State 隔离**: 每个环境使用独立的 state bucket 和 DynamoDB 表
2. **账户隔离**: 通过不同的 AWS CLI profile 实现完全的账户隔离
3. **版本固定**: Terraform 和 Provider 版本已在 versions.tf 中固定
4. **标签规范**: 所有资源自动打上环境标签（Environment, Project, Owner, ManagedBy）
5. **安全最佳实践**: S3 bucket 默认启用加密和公共访问阻止

## ✨ 已验证的功能

- ✅ 模块化架构（modules 层）
- ✅ 环境隔离（dev/test/prod）
- ✅ S3 bucket 模块
- ✅ 标签管理
- ✅ AWS Profile 配置
- ⏳ Lambda 模块（需要部署包）
- ⏳ API Gateway 模块（需要 Lambda）

