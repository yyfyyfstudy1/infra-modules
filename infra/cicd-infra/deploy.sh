#!/bin/bash
set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查参数
ACTION=${1:-plan}  # 默认为 plan

# 验证操作
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    log_error "无效的操作: $ACTION"
    echo "用法: ./deploy.sh [plan|apply|destroy]"
    echo "示例: ./deploy.sh plan"
    echo "     ./deploy.sh apply"
    exit 1
fi

log_info "CI/CD 基础设施部署脚本"
log_info "操作: $ACTION"

# 初始化 Terraform（如果需要）
if [ ! -d ".terraform" ]; then
    log_info "初始化 Terraform..."
    terraform init -backend-config=backend.hcl
fi

# 执行 Terraform 操作
case $ACTION in
    plan)
        log_info "生成执行计划..."
        terraform plan -out=cicd.tfplan
        log_success "执行计划已生成: cicd.tfplan"
        log_info "运行 './deploy.sh apply' 来应用此计划"
        ;;
    
    apply)
        if [ -f "cicd.tfplan" ]; then
            log_info "应用执行计划..."
            terraform apply cicd.tfplan
            rm -f cicd.tfplan
            log_success "CI/CD 基础设施部署成功！"
        else
            log_warning "未找到执行计划文件，直接应用..."
            terraform apply -auto-approve
            log_success "CI/CD 基础设施部署成功！"
        fi
        
        # 显示输出
        log_info "部署输出："
        terraform output
        
        log_info ""
        log_info "获取 Jenkins 初始管理员密码："
        log_info "$(terraform output -raw initial_admin_password_command)"
        ;;
    
    destroy)
        log_warning "即将销毁 CI/CD 基础设施的所有资源！"
        read -p "确认销毁吗？(yes/no): " -r
        if [ "$REPLY" = "yes" ]; then
            terraform destroy -auto-approve
            log_success "CI/CD 基础设施已销毁"
        else
            log_info "取消销毁操作"
        fi
        ;;
esac

