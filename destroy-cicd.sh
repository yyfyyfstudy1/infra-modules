#!/bin/bash
# Jenkins CI/CD 环境销毁脚本

set -e

echo "=================================="
echo "⚠️  Jenkins CI/CD 环境销毁脚本"
echo "=================================="
echo ""

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# 警告
echo -e "${RED}⚠️  警告：此操作将销毁以下资源：${NC}"
echo "  - Jenkins EC2 实例"
echo "  - Jenkins EBS 数据卷（包括所有 Jenkins 配置和任务）"
echo "  - ALB 负载均衡器"
echo "  - VPC 和网络资源"
echo ""
echo -e "${YELLOW}注意：Jenkins 的所有配置、任务、构建历史将被永久删除！${NC}"
echo ""

read -p "确定要继续吗？输入 'destroy' 确认: " CONFIRM

if [ "$CONFIRM" != "destroy" ]; then
    echo "销毁已取消"
    exit 0
fi

echo ""
echo "再次确认，输入项目名称 'chime-mvp' 以继续："
read -p "> " PROJECT_CONFIRM

if [ "$PROJECT_CONFIRM" != "chime-mvp" ]; then
    echo "项目名称不匹配，销毁已取消"
    exit 0
fi

echo ""
export AWS_PROFILE=dev-account
cd /Users/mt/infra-modules/infra/envs/cicd

echo "🗑️  开始销毁资源..."
terraform destroy -var-file=cicd.tfvars -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ 资源已销毁${NC}"
else
    echo ""
    echo -e "${RED}❌ 销毁失败${NC}"
    exit 1
fi

