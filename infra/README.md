# Chime MVP 基础设施

## 项目结构

```
infra/
├── modules/                 # 可复用模块层
│   ├── lambda_app/          # Lambda 函数模块
│   ├── apigw_http/          # API Gateway HTTP API 模块
│   └── s3_bucket/           # S3 桶模块
└── envs/                    # 环境落地层
    ├── dev/                 # 开发环境
    ├── test/                # 测试环境
    └── prod/                # 生产环境
```

## 设计原则

- **模块层（modules）**：定义资源的通用逻辑，不包含环境特定值
- **环境层（envs）**：引用模块并传入环境差异参数，保持薄薄一层

## 快速开始

### 前置条件

1. 安装 Terraform >= 1.5.0
2. 配置 AWS CLI profiles：`dev`、`test`、`prod`
3. 准备 Lambda 部署包：`dist/join.zip`

### 部署到 Dev 环境

```bash
# 1. 进入 dev 环境目录
cd infra/envs/dev

# 2. 初始化 Terraform（使用远端 state）
terraform init -backend-config=backend.hcl

# 3. 查看计划
terraform plan -var-file=dev.tfvars

# 4. 应用更改
terraform apply -var-file=dev.tfvars

# 5. 查看输出
terraform output
```

### 部署到 Test 环境

```bash
cd infra/envs/test
terraform init -backend-config=backend.hcl
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

### 部署到 Prod 环境

```bash
cd infra/envs/prod
terraform init -backend-config=backend.hcl
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## 环境差异

| 配置项 | Dev | Test | Prod |
|--------|-----|------|------|
| AWS Profile | dev | test | prod |
| Lambda 内存 | 512 MB | 512 MB | 1024 MB |
| Lambda 超时 | 20s | 20s | 30s |
| State Bucket | chime-mvp-tfstate-dev-syd | chime-mvp-tfstate-test-syd | chime-mvp-tfstate-prod-syd |

## 模块说明

### lambda_app

封装 Lambda 函数及其 IAM 角色、权限、环境变量等。

**输入：**
- `function_name`: 函数名称
- `handler`: 处理器
- `runtime`: 运行时
- `lambda_zip_path`: 部署包路径
- `env_vars`: 环境变量
- `custom_policy_json`: 自定义 IAM 策略

**输出：**
- `function_name`: 函数名称
- `function_arn`: 函数 ARN
- `invoke_arn`: 调用 ARN

### apigw_http

封装 API Gateway HTTP API、路由、Lambda 集成和权限。

**输入：**
- `api_name`: API 名称
- `routes`: 路由配置列表
- `cors_configuration`: CORS 配置
- `stage_name`: Stage 名称

**输出：**
- `api_invoke_url`: API 调用 URL
- `api_endpoint`: API 端点
- `api_id`: API ID

### s3_bucket

封装 S3 桶及其安全配置（版本控制、加密、公共访问阻止）。

**输入：**
- `bucket_name`: 桶名称
- `versioning_enabled`: 是否启用版本控制
- `force_destroy`: 是否允许强制删除

**输出：**
- `bucket_id`: 桶 ID
- `bucket_arn`: 桶 ARN

## 注意事项

1. **State 管理**：每个环境使用独立的 S3 bucket 和 DynamoDB 表存储 state
2. **账户隔离**：通过不同的 AWS CLI profile 实现账户隔离
3. **敏感信息**：避免将敏感信息硬编码，使用 AWS Secrets Manager 或 Parameter Store
4. **版本固定**：`versions.tf` 固定 Terraform 和 Provider 版本，保证可重复构建
5. **标签规范**：通过 `common_tags` 统一管理资源标签

## 常见任务

### 添加新的 Lambda 函数

1. 在 `envs/<env>/main.tf` 中添加新的 `module "lambda_xxx"` 块
2. 在 `apigw_http` 模块的 `routes` 中添加新路由
3. 更新 `outputs.tf` 暴露新资源

### 更新 Lambda 代码

```bash
# 打包新代码
# ... 生成 dist/join.zip

# 应用到 dev
cd infra/envs/dev
terraform apply -var-file=dev.tfvars
```

### 查看环境输出

```bash
cd infra/envs/dev
terraform output
```

## 故障排查

### 初始化失败

确保 backend.hcl 中的 S3 bucket 和 DynamoDB 表已创建：

```bash
# 创建 state bucket
aws s3 mb s3://chime-mvp-tfstate-dev-syd --profile dev

# 创建 DynamoDB 表
aws dynamodb create-table \
  --table-name tfstate-lock-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --profile dev
```

### Lambda 部署包不存在

确保 `dist/join.zip` 文件存在，或调整 `lambda_zip_path` 变量。

## 后续优化

- [ ] 添加 CloudWatch Logs 日志保留策略
- [ ] 添加 X-Ray 追踪
- [ ] 添加 API Gateway 访问日志
- [ ] 配置 Lambda 保留并发
- [ ] 添加 WAF 规则（prod）

