#!/bin/bash
# Jenkins CI/CD 环境一键部署脚本

set -e  # 遇到错误立即退出

echo "=================================="
echo "Jenkins CI/CD 环境部署脚本"
echo "=================================="
echo ""

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 检查必要工具
echo "📋 检查必要工具..."
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}❌ Terraform 未安装${NC}"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo -e "${RED}❌ AWS CLI 未安装${NC}"; exit 1; }
echo -e "${GREEN}✅ 工具检查通过${NC}"
echo ""

# 检查 AWS 配置
echo "📋 检查 AWS 配置..."
export AWS_PROFILE=dev-account
aws sts get-caller-identity >/dev/null 2>&1 || { 
    echo -e "${RED}❌ AWS Profile 'dev-account' 未配置或无效${NC}"
    echo "请运行: aws configure --profile dev-account"
    exit 1
}
ACCOUNT_ID=$(aws sts get-caller-identity --profile dev-account --query Account --output text)
echo -e "${GREEN}✅ 已连接到 AWS 账户: ${ACCOUNT_ID}${NC}"
echo ""

# 进入 cicd 目录
cd /Users/mt/infra-modules/infra/envs/cicd

# 检查 backend 资源
echo "📋 检查 Backend 资源..."
if aws s3 ls s3://chime-mvp-tfstate-dev-syd --profile dev-account >/dev/null 2>&1; then
    echo -e "${GREEN}✅ S3 Backend bucket 存在${NC}"
else
    echo -e "${YELLOW}⚠️  S3 Backend bucket 不存在，正在创建...${NC}"
    aws s3 mb s3://chime-mvp-tfstate-dev-syd --profile dev-account --region ap-southeast-2
    aws s3api put-bucket-versioning --bucket chime-mvp-tfstate-dev-syd --versioning-configuration Status=Enabled --profile dev-account
    echo -e "${GREEN}✅ S3 Bucket 创建完成${NC}"
fi

if aws dynamodb describe-table --table-name tfstate-lock-dev --region ap-southeast-2 --profile dev-account >/dev/null 2>&1; then
    echo -e "${GREEN}✅ DynamoDB 锁表存在${NC}"
else
    echo -e "${YELLOW}⚠️  DynamoDB 锁表不存在（这是正常的，Terraform 会自动处理）${NC}"
fi
echo ""

# Terraform 初始化
echo "🚀 步骤 1/4: Terraform 初始化..."
terraform init -backend-config=backend.hcl
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 初始化成功${NC}"
else
    echo -e "${RED}❌ 初始化失败${NC}"
    exit 1
fi
echo ""

# Terraform 验证
echo "🚀 步骤 2/4: 验证配置..."
terraform validate
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 配置验证通过${NC}"
else
    echo -e "${RED}❌ 配置验证失败${NC}"
    exit 1
fi
echo ""

# Terraform Plan
echo "🚀 步骤 3/4: 生成执行计划..."
terraform plan -var-file=cicd.tfvars -out=cicd.tfplan
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 执行计划生成成功${NC}"
else
    echo -e "${RED}❌ 执行计划生成失败${NC}"
    exit 1
fi
echo ""

# 显示预计成本
echo "=================================="
echo "📊 预计资源清单："
echo "=================================="
terraform show -no-color cicd.tfplan | grep "will be created" | head -20
echo ""
echo "💰 预计月成本: ~$123 USD"
echo "  - EC2 (t3.large):  ~$60"
echo "  - EBS (100GB):     ~$8"
echo "  - ALB:             ~$20"
echo "  - NAT Gateway:     ~$35"
echo ""

# 确认部署
echo -e "${YELLOW}⚠️  即将创建以上资源${NC}"
read -p "是否继续部署？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "部署已取消"
    exit 0
fi
echo ""

# Terraform Apply
echo "🚀 步骤 4/4: 部署资源（预计需要 10-15 分钟）..."
terraform apply cicd.tfplan

if [ $? -eq 0 ]; then
    echo ""
    echo "=================================="
    echo -e "${GREEN}✅ 部署成功！${NC}"
    echo "=================================="
    echo ""
    
    # 获取输出
    echo "📋 Jenkins 访问信息："
    echo "=================================="
    terraform output -no-color
    echo ""
    
    # 获取实例 ID
    INSTANCE_ID=$(terraform output -raw jenkins_instance_id 2>/dev/null)
    
    if [ ! -z "$INSTANCE_ID" ]; then
        echo "🔐 获取 Jenkins 初始密码："
        echo "=================================="
        echo "方法 1 - 使用 SSM Session Manager（推荐）:"
        echo ""
        echo "  aws ssm start-session \\"
        echo "    --target ${INSTANCE_ID} \\"
        echo "    --profile dev-account \\"
        echo "    --region ap-southeast-2"
        echo ""
        echo "  # 进入 EC2 后执行："
        echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
        echo ""
        echo "方法 2 - 等待 CloudWatch Logs（约 5 分钟后）:"
        echo ""
        echo "  aws logs tail /var/log/cloud-init-output.log \\"
        echo "    --follow \\"
        echo "    --profile dev-account \\"
        echo "    --region ap-southeast-2"
        echo ""
    fi
    
    echo "=================================="
    echo "📚 下一步："
    echo "=================================="
    echo "1. 访问 Jenkins URL"
    echo "2. 使用初始密码解锁"
    echo "3. 安装建议的插件"
    echo "4. 创建管理员账户"
    echo "5. 配置跨账号角色（参考 cicd/README.md）"
    echo ""
    echo -e "${GREEN}🎉 部署完成！${NC}"
    
else
    echo ""
    echo -e "${RED}❌ 部署失败${NC}"
    echo "请检查错误信息并重试"
    exit 1
fi

