# CICD Infrastructure - Jenkins 基础设施

## 📖 概述

这是 Chime MVP 项目的 CI/CD 基础设施层，独立管理 Jenkins 及其相关资源。与业务应用层（App Stack）完全分离，拥有独立的生命周期和状态管理。

## 🏗️ 架构

### 网络架构
```
Internet
   ↓
Application Load Balancer (公有子网)
   ↓
Jenkins EC2 Instance (私有子网)
   ↓
NAT Gateway → Internet Gateway
```

### 资源组成
- **VPC**: 自定义 VPC (10.0.0.0/16)
- **子网**: 2 个公有子网 + 2 个私有子网（跨 2 个可用区）
- **NAT Gateway**: 单个 NAT Gateway（私有子网出口）
- **Internet Gateway**: 公有子网入口
- **Jenkins EC2**: t3.large 实例，部署在私有子网
- **EBS 卷**: 100GB gp3，挂载到 `/var/lib/jenkins`
- **ALB**: Application Load Balancer，处理 HTTP/HTTPS 流量
- **Security Groups**: ALB-SG 和 Jenkins-SG
- **IAM 角色**: Jenkins 实例角色，含跨账号 AssumeRole 权限

## 🚀 部署指南

### 前置要求

1. 确保已配置 `dev-account` AWS CLI Profile
2. 获取 Test 和 Prod 账户的 AWS Account ID
3. （可选）准备 ACM 证书用于 HTTPS

### 首次部署

```bash
# 1. 进入目录
cd infra/cicd-infra

# 2. 修改配置文件
vim terraform.tfvars
# 修改以下关键参数:
# - test_account_id: 你的 test 账户 ID
# - prod_account_id: 你的 prod 账户 ID
# - allowed_cidr_blocks: 公司出口 IP
# - acm_certificate_arn: （可选）HTTPS 证书

# 3. 初始化
terraform init -backend-config=backend.hcl

# 4. 部署
./deploy.sh plan    # 预览变更
./deploy.sh apply   # 应用变更
```

### 获取 Jenkins 访问信息

```bash
# 查看所有输出
terraform output

# 获取 Jenkins URL
terraform output jenkins_url

# 获取 SSM 连接命令
terraform output initial_admin_password_command

# 使用 SSM Session Manager 连接到 Jenkins EC2
aws ssm start-session \
  --target $(terraform output -raw jenkins_instance_id) \
  --profile dev-account \
  --region ap-southeast-2

# 在 EC2 内查看 Jenkins 初始密码
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## 📝 配置文件说明

### `terraform.tfvars`

```hcl
# 基本配置
project_name = "chime-mvp"
owner        = "platform-team"
aws_region   = "ap-southeast-2"
aws_profile  = "dev-account"

# VPC 配置
vpc_cidr = "10.0.0.0/16"

# Jenkins EC2 配置
jenkins_instance_type = "t3.large"      # 8GB RAM
jenkins_ebs_size      = 100             # 100GB EBS
jenkins_key_name      = ""              # SSH 密钥（可选）

# 安全配置
allowed_cidr_blocks = ["0.0.0.0/0"]     # ⚠️ 改为公司 IP

# HTTPS 证书（可选）
acm_certificate_arn = ""

# 跨账号配置
test_account_id = "731894898059"        # 你的 test 账户 ID
prod_account_id = "522125011745"        # 你的 prod 账户 ID
```

## 🔧 手动操作

如果不使用部署脚本，可以手动执行：

```bash
# 初始化
terraform init -backend-config=backend.hcl

# 执行计划
terraform plan -out=cicd.tfplan

# 应用变更
terraform apply cicd.tfplan

# 查看输出
terraform output

# 销毁资源
terraform destroy
```

## 🗂️ 状态管理

### 后端配置（backend.hcl）
```hcl
bucket         = "chime-mvp-tfstate-dev-syd"
key            = "cicd-infra/terraform.tfstate"
region         = "ap-southeast-2"
dynamodb_table = "tfstate-lock-dev"
encrypt        = true
```

### 状态文件路径
- **S3 路径**: `s3://chime-mvp-tfstate-dev-syd/cicd-infra/terraform.tfstate`
- **独立管理**: 不使用 Workspace，独立于 App Stack

### 查看状态
```bash
# 列出所有资源
terraform state list

# 查看 Jenkins EC2
terraform state show module.jenkins_ec2.aws_instance.jenkins

# 查看 VPC
terraform state show module.vpc.aws_vpc.this

# 查看 ALB
terraform state show module.jenkins_alb.aws_lb.jenkins
```

## 🔐 安全配置

### Security Groups

**ALB Security Group (ALB-SG)**
- Ingress: 443 from `allowed_cidr_blocks`
- Ingress: 80 from `allowed_cidr_blocks`（可选）
- Egress: 8080, 50000 to Jenkins-SG

**Jenkins Security Group (Jenkins-SG)**
- Ingress: 8080, 50000 from ALB-SG
- Egress: All（访问外部依赖）

### IAM 权限

**Jenkins Instance Role**
```json
{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": [
    "arn:aws:iam::<TEST_ACCT>:role/JenkinsDeployerRole",
    "arn:aws:iam::<PROD_ACCT>:role/JenkinsDeployerRole"
  ]
}
```

附加托管策略:
- `AmazonSSMManagedInstanceCore` - SSM Session Manager 访问
- `CloudWatchAgentServerPolicy` - CloudWatch 日志和指标

## 🔄 跨账号部署配置

### 1. 在 Test 账户创建 JenkinsDeployerRole

```bash
# 切换到 test 账户
cd ../../cicd/cross-account-roles

# 使用 test-account profile 部署
terraform init
terraform apply -var="jenkins_role_arn=<Jenkins-Role-ARN>"
```

### 2. 在 Prod 账户创建 JenkinsDeployerRole

同样的步骤，切换到 prod 账户。

### 3. 在 Jenkins 中配置凭证

参考 `../../cicd/README.md` 中的 Jenkins 配置说明。

## 🛠️ 运维操作

### 连接到 Jenkins EC2

```bash
# 使用 SSM Session Manager（推荐）
aws ssm start-session \
  --target $(terraform output -raw jenkins_instance_id) \
  --profile dev-account \
  --region ap-southeast-2
```

### 检查 Jenkins 状态

```bash
# 在 EC2 内执行
sudo systemctl status jenkins
sudo journalctl -u jenkins -f
```

### 重启 Jenkins

```bash
# 方式 1: 通过 Web UI
http://<jenkins-url>/restart

# 方式 2: SSH 到 EC2
sudo systemctl restart jenkins
```

### 备份 Jenkins 数据

```bash
# EBS 卷快照（推荐）
aws ec2 create-snapshot \
  --volume-id <EBS-Volume-ID> \
  --description "Jenkins backup $(date +%Y%m%d)" \
  --profile dev-account
```

### 升级 Jenkins

```bash
# SSH 到 EC2
sudo systemctl stop jenkins
sudo dnf update jenkins -y
sudo systemctl start jenkins
```

## 📊 监控和日志

### CloudWatch Logs

Jenkins 日志自动发送到 CloudWatch Logs：
- Log Group: `/aws/jenkins/system`

### 查看日志

```bash
# 使用 AWS CLI
aws logs tail /aws/jenkins/system --follow --profile dev-account

# 在 EC2 内查看
sudo journalctl -u jenkins -f
sudo tail -f /var/log/jenkins/jenkins.log
```

### Health Check

ALB 定期对 Jenkins 进行健康检查：
- 路径: `/login`
- 间隔: 60秒
- 超时: 10秒
- 健康阈值: 2
- 不健康阈值: 5

## 🔄 更新和升级

### 更新 Jenkins 配置

```bash
# 1. 修改 terraform.tfvars
vim terraform.tfvars

# 2. 预览变更
./deploy.sh plan

# 3. 应用变更
./deploy.sh apply
```

### 更新 EC2 实例类型

```bash
# 修改 terraform.tfvars
jenkins_instance_type = "t3.xlarge"

# 应用变更
./deploy.sh plan
./deploy.sh apply
```

### 扩展 EBS 卷

```bash
# 修改 terraform.tfvars
jenkins_ebs_size = 200

# 应用变更（需要重启实例）
./deploy.sh apply
```

## 🆘 故障排查

### 问题 1: ALB 返回 502 Bad Gateway

**原因**: Jenkins 未启动或健康检查失败

**解决**:
```bash
# 连接到 EC2
aws ssm start-session --target <instance-id>

# 检查 Jenkins 状态
sudo systemctl status jenkins

# 查看日志
sudo journalctl -u jenkins -n 100

# 检查端口监听
sudo netstat -tlnp | grep 8080
```

### 问题 2: ALB 返回 504 Gateway Timeout

**原因**: Jenkins 启动中或响应慢

**解决**: 等待 Jenkins 完全启动（初次启动需 2-5 分钟）

### 问题 3: 无法通过 SSM 连接

**原因**: SSM Agent 未运行或 IAM 权限不足

**解决**:
```bash
# 检查 IAM 角色是否附加了 AmazonSSMManagedInstanceCore
terraform state show module.jenkins_ec2.aws_iam_role_policy_attachment.jenkins_ssm
```

### 问题 4: User Data 脚本失败

**原因**: 初始化脚本执行出错

**解决**:
```bash
# 查看 User Data 日志
sudo cat /var/log/user-data.log
sudo cat /var/log/cloud-init-output.log
```

## 📈 扩展和优化

### 添加 HTTPS

```bash
# 1. 申请 ACM 证书
aws acm request-certificate \
  --domain-name jenkins.yourdomain.com \
  --validation-method DNS

# 2. 更新 terraform.tfvars
acm_certificate_arn = "arn:aws:acm:region:account-id:certificate/xxx"

# 3. 应用变更
./deploy.sh apply
```

### 配置自动备份

使用 AWS Backup 服务：
```bash
# 创建备份计划
aws backup create-backup-plan \
  --backup-plan file://backup-plan.json
```

### 添加自定义域名

在 Route 53 中创建 CNAME 记录：
```bash
jenkins.yourdomain.com -> <ALB-DNS-Name>
```

## 📞 相关文档

- [主 README](../../README.md) - 项目总览
- [App Stack](../app/README.md) - 业务应用文档
- [Jenkins 配置](../../cicd/README.md) - Jenkins 详细配置
- [跨账号角色](../../cicd/cross-account-roles/) - IAM 角色配置

