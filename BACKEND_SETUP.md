# Backend 配置完成汇总

## ✅ 配置状态

所有环境的 Terraform Backend 已成功配置并使用 AWS S3 进行管理。

## 📦 已创建的资源

### Dev 环境
| 资源类型 | 资源名称 | 区域 | 状态 |
|---------|---------|------|------|
| S3 Bucket | `chime-mvp-tfstate-dev-syd` | ap-southeast-2 | ✅ 已创建 |
| DynamoDB 表 | `tfstate-lock-dev` | ap-southeast-2 | ✅ 已创建 |
| AWS Profile | `dev-account` | - | ✅ 已配置 |

**State 文件路径：** `s3://chime-mvp-tfstate-dev-syd/envs/dev/terraform.tfstate`

### Test 环境
| 资源类型 | 资源名称 | 区域 | 状态 |
|---------|---------|------|------|
| S3 Bucket | `chime-mvp-tfstate-test-syd` | ap-southeast-2 | ✅ 已创建 |
| DynamoDB 表 | `tfstate-lock-test` | ap-southeast-2 | ✅ 已创建 |
| AWS Profile | `test-account` | - | ✅ 已配置 |

**State 文件路径：** `s3://chime-mvp-tfstate-test-syd/envs/test/terraform.tfstate`

### Prod 环境
| 资源类型 | 资源名称 | 区域 | 状态 |
|---------|---------|------|------|
| S3 Bucket | `chime-mvp-tfstate-prod-syd` | ap-southeast-2 | ✅ 已存在 |
| DynamoDB 表 | `tfstate-lock-prod` | ap-southeast-2 | ✅ 已创建 |
| AWS Profile | `prod-account` | - | ✅ 已配置 |

**State 文件路径：** `s3://chime-mvp-tfstate-prod-syd/envs/prod/terraform.tfstate`

## 🔒 安全配置

所有 S3 Backend Buckets 已配置以下安全特性：

### 1. 版本控制
- **状态：** ✅ 已启用
- **用途：** 可以恢复到任何历史版本的 state
- **命令验证：**
  ```bash
  aws s3api get-bucket-versioning --bucket chime-mvp-tfstate-dev-syd --profile dev-account
  ```

### 2. 服务端加密
- **状态：** ✅ 已启用
- **算法：** AES256
- **用途：** 所有 state 文件自动加密存储
- **命令验证：**
  ```bash
  aws s3api get-bucket-encryption --bucket chime-mvp-tfstate-dev-syd --profile dev-account
  ```

### 3. 公共访问阻止
- **状态：** ✅ 已启用
- **配置：** 
  - BlockPublicAcls: true
  - IgnorePublicAcls: true
  - BlockPublicPolicy: true
  - RestrictPublicBuckets: true
- **用途：** 防止 state 文件被公开访问
- **命令验证：**
  ```bash
  aws s3api get-public-access-block --bucket chime-mvp-tfstate-dev-syd --profile dev-account
  ```

### 4. DynamoDB 状态锁
- **状态：** ✅ 已启用
- **用途：** 防止多人同时修改 state 造成冲突
- **计费模式：** PAY_PER_REQUEST（按需付费）
- **命令验证：**
  ```bash
  aws dynamodb describe-table --table-name tfstate-lock-dev --region ap-southeast-2 --profile dev-account
  ```

## 🚀 使用方法

### 方法一：使用辅助脚本（推荐）

每个环境目录下都有 `tf.sh` 脚本，自动配置正确的 AWS profile：

```bash
cd infra/envs/dev
./tf.sh init      # 初始化
./tf.sh plan      # 查看计划
./tf.sh apply     # 应用更改
./tf.sh destroy   # 销毁资源
```

### 方法二：手动指定 AWS Profile

```bash
cd infra/envs/dev
AWS_PROFILE=dev-account terraform init -backend-config=backend.hcl
AWS_PROFILE=dev-account terraform plan -var-file=dev.tfvars
AWS_PROFILE=dev-account terraform apply -var-file=dev.tfvars
```

## 📊 Backend 配置文件

每个环境的 `backend.hcl` 文件内容：

### Dev: `infra/envs/dev/backend.hcl`
```hcl
bucket         = "chime-mvp-tfstate-dev-syd"
key            = "envs/dev/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true
```

### Test: `infra/envs/test/backend.hcl`
```hcl
bucket         = "chime-mvp-tfstate-test-syd"
key            = "envs/test/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-test"
encrypt        = true
```

### Prod: `infra/envs/prod/backend.hcl`
```hcl
bucket         = "chime-mvp-tfstate-prod-syd"
key            = "envs/prod/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-prod"
encrypt        = true
```

## 🔍 验证 Backend 配置

### 检查 S3 Bucket
```bash
# Dev
aws s3 ls s3://chime-mvp-tfstate-dev-syd/envs/dev/ --profile dev-account

# Test
aws s3 ls s3://chime-mvp-tfstate-test-syd/envs/test/ --profile test-account

# Prod
aws s3 ls s3://chime-mvp-tfstate-prod-syd/envs/prod/ --profile prod-account
```

### 检查 DynamoDB 表
```bash
# Dev
aws dynamodb describe-table --table-name tfstate-lock-dev --region ap-southeast-2 --profile dev-account

# Test
aws dynamodb describe-table --table-name tfstate-lock-test --region ap-southeast-2 --profile test-account

# Prod
aws dynamodb describe-table --table-name tfstate-lock-prod --region ap-southeast-2 --profile prod-account
```

### 检查 Terraform State
```bash
cd infra/envs/dev
AWS_PROFILE=dev-account terraform show
```

## 💡 最佳实践

### 1. 环境隔离
- ✅ 每个环境使用独立的 AWS 账户
- ✅ 每个环境使用独立的 S3 bucket
- ✅ 每个环境使用独立的 DynamoDB 锁表

### 2. 安全性
- ✅ State bucket 启用版本控制
- ✅ State bucket 启用加密
- ✅ State bucket 阻止公共访问
- ✅ 使用 DynamoDB 锁防止并发修改

### 3. 权限管理
- ✅ 使用 AWS CLI Profile 分离不同账户的凭证
- ✅ 最小权限原则：每个账户只能访问自己的资源

### 4. State 恢复
如果需要恢复到历史版本：
```bash
# 列出 state 文件的所有版本
aws s3api list-object-versions \
  --bucket chime-mvp-tfstate-dev-syd \
  --prefix envs/dev/terraform.tfstate \
  --profile dev-account

# 下载特定版本
aws s3api get-object \
  --bucket chime-mvp-tfstate-dev-syd \
  --key envs/dev/terraform.tfstate \
  --version-id <VERSION_ID> \
  terraform.tfstate.backup \
  --profile dev-account
```

## ⚠️ 重要提示

1. **不要删除 Backend 资源**：删除 S3 bucket 或 DynamoDB 表会导致无法管理基础设施
2. **定期备份**：虽然启用了版本控制，但建议定期备份 state 文件
3. **权限控制**：限制对 state bucket 和 DynamoDB 表的访问权限
4. **团队协作**：使用 DynamoDB 锁确保团队成员不会同时修改 state

## 📞 故障排查

### 问题：AccessDenied 错误
**原因：** AWS Profile 配置不正确或缺少权限

**解决：**
```bash
# 检查当前使用的 profile
aws sts get-caller-identity --profile dev-account

# 确保使用正确的 profile 执行 terraform
AWS_PROFILE=dev-account terraform init -backend-config=backend.hcl
```

### 问题：Lock 超时
**原因：** 上次 terraform 操作被中断，锁未释放

**解决：**
```bash
# 手动删除锁（谨慎操作）
cd infra/envs/dev
AWS_PROFILE=dev-account terraform force-unlock <LOCK_ID>
```

### 问题：State 文件损坏
**原因：** 并发修改或网络问题

**解决：**
```bash
# 从 S3 恢复历史版本（见上文"State 恢复"部分）
```

## ✨ 总结

✅ **所有环境的 Backend 已完全配置并可用**
- Dev、Test、Prod 环境独立隔离
- State 文件安全存储在 S3
- DynamoDB 锁防止并发冲突
- 辅助脚本简化操作流程

现在可以安全地在各个环境中部署和管理基础设施了！

