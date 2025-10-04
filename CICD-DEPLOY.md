# 🚀 Jenkins CI/CD 一键部署指南

## ✅ 部署前检查

### 1. 确认 AWS CLI 配置
```bash
# 检查 dev-account profile
aws sts get-caller-identity --profile dev-account

# 应该看到类似输出：
# {
#     "UserId": "xxx",
#     "Account": "859525219186",  # Dev 账户
#     "Arn": "arn:aws:iam::859525219186:..."
# }
```

### 2. 确认 Terraform 安装
```bash
terraform version
# 应该 >= 1.5.0
```

---

## 🎯 一键部署

### 方法一：使用部署脚本（推荐）

```bash
cd /Users/mt/infra-modules

# 添加执行权限
chmod +x deploy-cicd.sh destroy-cicd.sh

# 执行部署（10-15 分钟）
./deploy-cicd.sh
```

脚本会自动：
1. ✅ 检查工具和配置
2. ✅ 检查/创建 Backend 资源
3. ✅ Terraform 初始化
4. ✅ 验证配置
5. ✅ 生成执行计划
6. ✅ 确认后部署
7. ✅ 显示 Jenkins 访问信息

### 方法二：手动执行（高级用户）

```bash
cd /Users/mt/infra-modules/infra/envs/cicd
export AWS_PROFILE=dev-account

# 1. 初始化
terraform init -backend-config=backend.hcl

# 2. 查看计划
terraform plan -var-file=cicd.tfvars

# 3. 部署
terraform apply -var-file=cicd.tfvars

# 4. 查看输出
terraform output
```

---

## 📋 部署后操作

### 1. 获取 Jenkins 初始密码

部署完成后，使用以下方法获取密码：

#### 方法 A：SSM Session Manager（推荐）
```bash
# 获取实例 ID（从 terraform output 获取）
INSTANCE_ID="i-xxxxxxxxxxxxx"

# 连接到实例
aws ssm start-session \
  --target ${INSTANCE_ID} \
  --profile dev-account \
  --region ap-southeast-2

# 在 EC2 内执行
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

#### 方法 B：等待 5 分钟后查看 CloudWatch Logs
```bash
# Jenkins 启动需要几分钟
# 密码会输出到系统日志
```

### 2. 访问 Jenkins

```bash
# 从 terraform output 获取 URL
terraform output jenkins_url

# 例如：
# http://chime-mvp-cicd-alb-12345.ap-southeast-2.elb.amazonaws.com
```

### 3. 配置 Jenkins

1. **解锁 Jenkins**
   - 粘贴初始密码

2. **安装插件**
   - 选择 "Install suggested plugins"
   - 额外安装：Pipeline、Git、AWS Steps、Credentials Binding

3. **创建管理员账户**
   - 设置用户名和密码

4. **配置 AWS 凭证**
   - Manage Jenkins → Credentials
   - 添加 dev/test/prod 角色 ARN

---

## 🔧 故障排查

### 问题 1：AWS Profile 错误
```bash
# 配置 dev-account
aws configure --profile dev-account

# 测试
aws sts get-caller-identity --profile dev-account
```

### 问题 2：Backend Bucket 不存在
```bash
# 手动创建
aws s3 mb s3://chime-mvp-tfstate-dev-syd \
  --profile dev-account \
  --region ap-southeast-2
```

### 问题 3：Jenkins 无法访问
```bash
# 检查 ALB 健康状态
cd /Users/mt/infra-modules/infra/envs/cicd
terraform output

# 检查安全组
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=chime-mvp-cicd-*" \
  --profile dev-account
```

### 问题 4：部署超时
```bash
# 查看详细日志
terraform apply -var-file=cicd.tfvars -parallelism=1
```

---

## 🗑️ 销毁环境

### 使用脚本
```bash
cd /Users/mt/infra-modules
./destroy-cicd.sh
```

### 手动销毁
```bash
cd /Users/mt/infra-modules/infra/envs/cicd
export AWS_PROFILE=dev-account
terraform destroy -var-file=cicd.tfvars
```

---

## 💰 成本估算

| 资源 | 规格 | 月成本（USD） |
|------|------|---------------|
| EC2 (t3.large) | 2 vCPU, 8GB | ~$60 |
| EBS (gp3) | 100GB | ~$8 |
| ALB | 1 个 | ~$20 |
| NAT Gateway | 1 个 | ~$35 |
| **总计** | | **~$123/月** |

---

## 📚 下一步

1. ✅ 部署完成
2. ⏭️ 配置 Jenkins
3. ⏭️ 创建跨账号角色（test/prod）
4. ⏭️ 创建 Pipeline Job
5. ⏭️ 测试部署流程

详细文档：`cicd/README.md`

---

## ⚡ 快速命令参考

```bash
# 部署
./deploy-cicd.sh

# 查看输出
cd infra/envs/cicd && terraform output

# 销毁
./destroy-cicd.sh

# 重新部署
./destroy-cicd.sh && ./deploy-cicd.sh
```

---

**准备好了吗？运行 `./deploy-cicd.sh` 开始部署！** 🚀

