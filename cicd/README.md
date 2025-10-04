# Jenkins CI/CD 基础设施部署指南

## 🎯 架构概览

```
┌──────────────────────────────────────────────────────┐
│                    Dev Account                        │
│  ┌─────────────────────────────────────────────┐    │
│  │              VPC (10.0.0.0/16)              │    │
│  │  ┌────────────────┐   ┌──────────────────┐ │    │
│  │  │  Public Subnet │   │  Private Subnet   │ │    │
│  │  │  ┌───────────┐ │   │  ┌─────────────┐ │ │    │
│  │  │  │    ALB    │◄┼───┼──┤  Jenkins EC2 │ │ │    │
│  │  │  │  (HTTPS)  │ │   │  │   + EBS 100G │ │ │    │
│  │  │  └───────────┘ │   │  └─────────────┘ │ │    │
│  │  └────────────────┘   └──────────────────┘ │    │
│  │             ▲                    │          │    │
│  └─────────────┼────────────────────┼──────────┘    │
│                │                    │                │
│            HTTPS (443)     AssumeRole (sts)         │
│                │                    ▼                │
└────────────────┼──────────────────────────────────────┘
                 │            ┌────────────────────────┐
             Internet         │  Test/Prod Accounts    │
                 │            │  JenkinsDeployerRole   │
                 │            └────────────────────────┘
            Company IP
```

## 📋 部署前准备

### 1. 账户信息确认

```bash
# Dev 账户（部署 Jenkins）
Dev Account ID:  859525219186
Profile:         dev-account

# Test 账户
Test Account ID: 731894898059
Profile:         test-account

# Prod 账户
Prod Account ID: 522125011745
Profile:         prod-account
```

### 2. 必需工具

- Terraform >= 1.5.0
- AWS CLI v2
- Git

### 3. 网络规划

默认配置：
- VPC CIDR: `10.0.0.0/16`
- 公有子网: `10.0.1.0/24`, `10.0.2.0/24`
- 私有子网: `10.0.10.0/24`, `10.0.20.0/24`

---

## 🚀 部署步骤

### 第一步：部署 Jenkins 基础设施（Dev 账户）

```bash
cd /Users/mt/infra-modules/infra/envs/cicd

# 1. 修改配置文件
vim cicd.tfvars

# 重点修改：
# - allowed_cidr_blocks: 改为你公司的出口 IP
# - jenkins_key_name: 如果需要 SSH，填写密钥对名称
# - acm_certificate_arn: 如果有 HTTPS 证书，填写 ARN

# 2. 初始化
export AWS_PROFILE=dev-account
terraform init -backend-config=backend.hcl

# 3. 查看计划
terraform plan -var-file=cicd.tfvars

# 4. 部署（约 10-15 分钟）
terraform apply -var-file=cicd.tfvars

# 5. 获取输出
terraform output
```

**输出示例：**
```
jenkins_url                     = "http://chime-mvp-cicd-alb-12345.ap-southeast-2.elb.amazonaws.com"
jenkins_instance_id             = "i-0123456789abcdef0"
jenkins_instance_private_ip     = "10.0.10.123"
jenkins_role_arn                = "arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role"
```

### 第二步：获取 Jenkins 初始密码

```bash
# 方法 1：使用 SSM Session Manager（推荐）
aws ssm start-session \\
  --target i-0123456789abcdef0 \\
  --profile dev-account \\
  --region ap-southeast-2

# 在 EC2 实例内执行：
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# 方法 2：使用 SSH（如果配置了密钥对）
ssh -i your-key.pem ec2-user@<jenkins-private-ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 第三步：配置 Test 账户的部署角色

```bash
cd /Users/mt/infra-modules/cicd/cross-account-roles

# 1. 编辑配置（填写 Jenkins 角色 ARN）
vim terraform.tfvars

# 内容：
jenkins_role_arn = "arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role"

# 2. 在 Test 账户部署角色
export AWS_PROFILE=test-account
terraform init
terraform apply -var="jenkins_role_arn=arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role" \\
  test-account-role.tf

# 3. 记录输出的角色 ARN
terraform output role_arn
# 输出：arn:aws:iam::731894898059:role/JenkinsDeployerRole
```

### 第四步：配置 Prod 账户的部署角色

```bash
# 在 Prod 账户部署角色（步骤同 Test）
export AWS_PROFILE=prod-account
terraform init
terraform apply -var="jenkins_role_arn=arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role" \\
  prod-account-role.tf

# 记录输出
terraform output role_arn
# 输出：arn:aws:iam::522125011745:role/JenkinsDeployerRole
```

### 第五步：配置 Jenkins

#### 1. 访问 Jenkins

```
URL: http://chime-mvp-cicd-alb-12345.ap-southeast-2.elb.amazonaws.com
```

#### 2. 解锁 Jenkins

粘贴刚才获取的初始密码

#### 3. 安装插件

选择 **"Install suggested plugins"**，额外安装：
- Pipeline
- Git
- Credentials Binding
- AWS Steps
- AnsiColor
- Timestamper

#### 4. 创建管理员账户

用户名/密码自行设置

#### 5. 配置凭证

**Jenkins 首页 → Manage Jenkins → Credentials → System → Global credentials**

添加以下凭证：

**凭证 1 - AWS Role (Dev)**
- Kind: `Secret text`
- Secret: `arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role`
- ID: `aws-role-dev`

**凭证 2 - AWS Role (Test)**
- Kind: `Secret text`
- Secret: `arn:aws:iam::731894898059:role/JenkinsDeployerRole`
- ID: `aws-role-test`

**凭证 3 - AWS Role (Prod)**
- Kind: `Secret text`
- Secret: `arn:aws:iam::522125011745:role/JenkinsDeployerRole`
- ID: `aws-role-prod`

### 第六步：创建 Pipeline Job

#### 1. 新建 Item

- 名称: `Terraform-Deploy`
- 类型: `Pipeline`

#### 2. 配置 Pipeline

**Pipeline 定义:**
- Definition: `Pipeline script from SCM`
- SCM: `Git`
- Repository URL: `your-git-repo-url`
- Script Path: `cicd/jenkins-pipelines/Jenkinsfile.terraform`

#### 3. 保存并构建

点击 **"Build with Parameters"**，选择环境和操作

---

## 🎯 使用流程

### Dev 环境部署

```
1. Jenkins → Terraform-Deploy
2. 选择参数：
   - ENV: dev
   - ACTION: apply
   - AUTO_APPROVE: ✓
3. 点击 "Build"
4. 等待完成
```

### Test 环境部署

```
1. Jenkins → Terraform-Deploy
2. 选择参数：
   - ENV: test
   - ACTION: plan
3. 查看 plan 输出
4. 如果正常，再次构建：
   - ENV: test
   - ACTION: apply
   - AUTO_APPROVE: ✓ (可选)
5. 点击 "Build"
```

### Prod 环境部署

```
1. Jenkins → Terraform-Deploy
2. 选择参数：
   - ENV: prod
   - ACTION: plan
3. 团队审查 plan 输出
4. 获得批准后，再次构建：
   - ENV: prod
   - ACTION: apply
   - AUTO_APPROVE: ✗ (必须)
5. 点击 "Build"
6. Pipeline 会暂停，等待手动审批
7. 点击 "Deploy" 继续
```

---

## 🔧 故障排查

### 1. Jenkins 无法访问

```bash
# 检查 ALB 健康检查
aws elbv2 describe-target-health \\
  --target-group-arn <target-group-arn> \\
  --profile dev-account

# 检查 EC2 实例状态
aws ec2 describe-instances \\
  --instance-ids <instance-id> \\
  --profile dev-account
```

### 2. 跨账号部署失败

```bash
# 验证角色信任关系
aws iam get-role \\
  --role-name JenkinsDeployerRole \\
  --profile test-account

# 测试 AssumeRole
aws sts assume-role \\
  --role-arn arn:aws:iam::<test-account-id>:role/JenkinsDeployerRole \\
  --role-session-name test \\
  --profile dev-account
```

### 3. Jenkins 数据丢失

```bash
# 检查 EBS 挂载
ssh ec2-user@<jenkins-ip>
df -h | grep jenkins

# 恢复 EBS 快照（如果有）
aws ec2 describe-snapshots \\
  --filters "Name=volume-id,Values=<volume-id>" \\
  --profile dev-account
```

---

## 📊 成本估算

### 基础设施成本（ap-southeast-2，按月）

| 资源 | 规格 | 月成本（USD） |
|------|------|---------------|
| EC2 (t3.large) | 2 vCPU, 8GB RAM | ~$60 |
| EBS (gp3) | 100GB | ~$8 |
| ALB | 1 个 | ~$20 |
| NAT Gateway | 1 个 | ~$35 |
| **总计** | | **~$123/月** |

### 节省成本建议

1. **使用 EC2 Spot 实例**（可节省 70%）
2. **非工作时间关闭**（可节省 50%）
3. **使用 VPC Endpoint**（替代 NAT Gateway）
4. **减少 EBS 大小**（根据实际使用）

---

## 🔒 安全加固（生产环境必做）

### 1. 限制访问 IP

```hcl
# cicd.tfvars
allowed_cidr_blocks = ["203.0.113.0/24"]  # 你公司的出口 IP
```

### 2. 启用 HTTPS

```bash
# 申请 ACM 证书
aws acm request-certificate \\
  --domain-name jenkins.dev.yourcompany.com \\
  --validation-method DNS \\
  --profile dev-account

# 更新配置
# cicd.tfvars
acm_certificate_arn = "arn:aws:acm:ap-southeast-2:xxx:certificate/xxx"
```

### 3. 启用审计日志

```bash
# CloudTrail（在 dev 账户）
aws cloudtrail create-trail \\
  --name jenkins-audit \\
  --s3-bucket-name jenkins-audit-logs \\
  --profile dev-account
```

### 4. 启用备份

```bash
# AWS Backup（每日备份 EBS）
aws backup create-backup-plan \\
  --backup-plan file://backup-plan.json \\
  --profile dev-account
```

---

## 📚 参考文档

- [Jenkins 官方文档](https://www.jenkins.io/doc/)
- [AWS Pipeline 插件](https://github.com/jenkinsci/pipeline-aws-plugin)
- [Terraform Backend S3](https://www.terraform.io/language/settings/backends/s3)
- [AWS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)

---

## ✅ 部署检查清单

- [ ] 修改 `cicd.tfvars` 中的安全配置
- [ ] 部署 Jenkins 基础设施到 Dev 账户
- [ ] 获取 Jenkins 初始密码
- [ ] 创建 Test 账户的部署角色
- [ ] 创建 Prod 账户的部署角色
- [ ] 配置 Jenkins 凭证
- [ ] 创建 Pipeline Job
- [ ] 测试 Dev 环境部署
- [ ] 测试 Test 环境部署
- [ ] 配置 HTTPS（可选）
- [ ] 配置备份策略
- [ ] 限制访问 IP
- [ ] 配置监控告警

---

**部署完成后，你将拥有：**

✅ 一个企业级的 Jenkins CI/CD 平台  
✅ 跨账号安全部署能力  
✅ 完整的审计和备份  
✅ 可扩展的 Pipeline 模板

**祝部署顺利！** 🚀

