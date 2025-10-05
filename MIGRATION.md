# 🔄 项目结构迁移指南

本指南帮助你从旧的多目录结构迁移到新的单入口多环境结构。

## 📊 结构对比

### 旧结构（已废弃）
```
infra/
└── envs/
    ├── dev/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── dev.tfvars
    │   └── backend.hcl
    ├── test/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── test.tfvars
    │   └── backend.hcl
    ├── prod/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── prod.tfvars
    │   └── backend.hcl
    └── cicd/
        ├── main.tf
        ├── variables.tf
        ├── cicd.tfvars
        └── backend.hcl
```

### 新结构（推荐）
```
infra/
├── app/                    # 单入口，多环境
│   ├── main.tf            # 所有环境共用
│   ├── variables.tf
│   ├── backend.hcl        # 使用 Workspace
│   └── envs/
│       ├── dev.tfvars
│       ├── test.tfvars
│       └── prod.tfvars
└── cicd-infra/            # 独立入口
    ├── main.tf
    ├── variables.tf
    ├── backend.hcl        # 独立状态
    └── terraform.tfvars
```

## 🎯 迁移优势

✅ **一份代码，多处运行** - 不需要在每个环境重复维护 `main.tf`  
✅ **配置集中管理** - 环境差异一目了然  
✅ **Workspace 隔离** - 状态文件自动隔离  
✅ **部署脚本统一** - 一个脚本支持所有环境  
✅ **独立生命周期** - App 和 CI/CD 互不干扰  

## 🚀 迁移步骤

### Step 1: 备份现有状态

**⚠️ 重要：在迁移前务必备份状态文件！**

```bash
# 备份 S3 中的状态文件
aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/dev/terraform.tfstate \
  ./backup/dev-terraform.tfstate \
  --profile dev-account

aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/test/terraform.tfstate \
  ./backup/test-terraform.tfstate \
  --profile test-account

aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/prod/terraform.tfstate \
  ./backup/prod-terraform.tfstate \
  --profile prod-account

aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/cicd/terraform.tfstate \
  ./backup/cicd-terraform.tfstate \
  --profile dev-account
```

### Step 2: 销毁旧资源（推荐方式）

如果可以接受短暂的停机时间，最简单的方式是：

1. 销毁所有旧资源
2. 使用新结构重新部署

```bash
# 销毁旧的 dev 环境
cd infra/envs/dev
terraform destroy -var-file=dev.tfvars -auto-approve

# 销毁旧的 test 环境
cd ../test
terraform destroy -var-file=test.tfvars -auto-approve

# 销毁旧的 prod 环境
cd ../prod
terraform destroy -var-file=prod.tfvars -auto-approve

# 销毁旧的 cicd 环境
cd ../cicd
terraform destroy -var-file=cicd.tfvars -auto-approve
```

### Step 3: 使用新结构重新部署

```bash
# 部署 App Stack - Dev
cd infra/app
terraform init -backend-config=backend.hcl
terraform workspace new dev
./deploy.sh dev apply

# 部署 App Stack - Test
terraform workspace new test
./deploy.sh test apply

# 部署 App Stack - Prod
terraform workspace new prod
./deploy.sh prod apply

# 部署 CICD Infrastructure
cd ../cicd-infra
terraform init -backend-config=backend.hcl
./deploy.sh apply
```

## 🔧 高级迁移（零停机）

如果需要零停机迁移，可以使用状态迁移：

### Step 1: 迁移 Dev 环境状态

```bash
# 1. 初始化新结构
cd infra/app
terraform init -backend-config=backend.hcl

# 2. 创建 dev workspace
terraform workspace new dev

# 3. 从旧位置拉取状态
terraform state pull > /tmp/dev-state.json

# 4. 手动复制旧状态到新位置
aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/dev/terraform.tfstate \
  s3://chime-mvp-tfstate-dev-syd/env:/dev/app/terraform.tfstate

# 5. 刷新状态
terraform refresh -var-file=envs/dev.tfvars

# 6. 验证状态
terraform plan -var-file=envs/dev.tfvars
```

### Step 2: 迁移 Test 和 Prod 环境

重复 Step 1 的步骤，分别针对 `test` 和 `prod` workspace。

### Step 3: 迁移 CICD 环境

```bash
# 1. 初始化 CICD Infrastructure
cd infra/cicd-infra
terraform init -backend-config=backend.hcl

# 2. 复制旧状态到新位置
aws s3 cp s3://chime-mvp-tfstate-dev-syd/envs/cicd/terraform.tfstate \
  s3://chime-mvp-tfstate-dev-syd/cicd-infra/terraform.tfstate

# 3. 刷新状态
terraform refresh

# 4. 验证状态
terraform plan
```

## ⚠️ 状态路径变更

### 旧的状态路径
- Dev: `s3://bucket/envs/dev/terraform.tfstate`
- Test: `s3://bucket/envs/test/terraform.tfstate`
- Prod: `s3://bucket/envs/prod/terraform.tfstate`
- CICD: `s3://bucket/envs/cicd/terraform.tfstate`

### 新的状态路径
- Dev: `s3://bucket/env:/dev/app/terraform.tfstate` (Workspace)
- Test: `s3://bucket/env:/test/app/terraform.tfstate` (Workspace)
- Prod: `s3://bucket/env:/prod/app/terraform.tfstate` (Workspace)
- CICD: `s3://bucket/cicd-infra/terraform.tfstate` (独立)

## 🧹 清理旧文件

迁移完成并验证无误后，可以清理旧文件：

```bash
# 删除旧的环境目录（保留模块）
rm -rf infra/envs/dev
rm -rf infra/envs/test
rm -rf infra/envs/prod
rm -rf infra/envs/cicd

# 可选：删除旧的 S3 状态文件（确认新状态工作正常后）
aws s3 rm s3://chime-mvp-tfstate-dev-syd/envs/ --recursive
```

## ✅ 迁移验证清单

完成迁移后，验证以下内容：

- [ ] 所有环境的资源都正常运行
- [ ] 可以成功执行 `terraform plan` 且无变更
- [ ] 可以成功执行 `terraform apply` 应用新的变更
- [ ] 所有输出（outputs）正常
- [ ] API Gateway 可以访问
- [ ] Lambda 函数可以正常调用
- [ ] Jenkins 可以正常访问（如果部署了）
- [ ] 旧的状态文件已备份

## 🆘 回滚方案

如果迁移出现问题，可以立即回滚：

### 方案 1: 恢复旧状态文件

```bash
# 恢复 dev 环境
aws s3 cp ./backup/dev-terraform.tfstate \
  s3://chime-mvp-tfstate-dev-syd/envs/dev/terraform.tfstate

# 恢复其他环境...
```

### 方案 2: 使用新结构重新部署

如果已经销毁了旧资源：

```bash
cd infra/app
./deploy.sh dev apply
./deploy.sh test apply
./deploy.sh prod apply
```

## 📝 迁移检查表

```
[ ] 1. 阅读并理解新旧结构差异
[ ] 2. 备份所有环境的状态文件到本地
[ ] 3. 备份旧的 Terraform 代码到 git 分支
[ ] 4. 决定迁移策略（销毁重建 vs 状态迁移）
[ ] 5. 执行迁移
    [ ] 5.1 迁移 dev 环境
    [ ] 5.2 验证 dev 环境
    [ ] 5.3 迁移 test 环境
    [ ] 5.4 验证 test 环境
    [ ] 5.5 迁移 prod 环境
    [ ] 5.6 验证 prod 环境
    [ ] 5.7 迁移 cicd 环境
    [ ] 5.8 验证 cicd 环境
[ ] 6. 运行完整的验证测试
[ ] 7. 更新文档和 CI/CD 脚本
[ ] 8. 清理旧文件和状态
[ ] 9. 通知团队成员新的工作流程
```

## 🎓 迁移后的新工作流

### 部署流程

**旧方式（已废弃）:**
```bash
cd infra/envs/dev
terraform apply -var-file=dev.tfvars
```

**新方式:**
```bash
cd infra/app
./deploy.sh dev apply
```

### 环境切换

**旧方式:**
```bash
cd infra/envs/test  # 切换目录
```

**新方式:**
```bash
terraform workspace select test  # 切换 workspace
```

### 查看状态

**旧方式:**
```bash
cd infra/envs/prod
terraform state list
```

**新方式:**
```bash
cd infra/app
terraform workspace select prod
terraform state list
```

## 📞 需要帮助？

如果在迁移过程中遇到问题：

1. 查看 [主 README](README.md)
2. 查看 [快速开始指南](QUICKSTART.md)
3. 查看 [App Stack README](infra/app/README.md)
4. 查看 [CICD README](infra/cicd-infra/README.md)

## 🎉 迁移完成

恭喜！你已经成功迁移到新的项目结构。

新结构的优势：
- ✅ 更清晰的代码组织
- ✅ 更少的重复代码
- ✅ 更简单的维护
- ✅ 更灵活的扩展

享受新的工作流程吧！🚀

