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
if [ $# -eq 0 ]; then
    log_error "请指定环境: dev, test, 或 prod"
    echo "用法: ./deploy.sh <环境> [plan|apply|destroy]"
    echo "示例: ./deploy.sh dev plan"
    echo "     ./deploy.sh test apply"
    exit 1
fi

ENV=$1
ACTION=${2:-plan}  # 默认为 plan

# 验证环境
if [[ ! "$ENV" =~ ^(dev|test|prod)$ ]]; then
    log_error "无效的环境: $ENV"
    echo "有效环境: dev, test, prod"
    exit 1
fi

# 验证操作
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    log_error "无效的操作: $ACTION"
    echo "有效操作: plan, apply, destroy"
    exit 1
fi

TFVARS_FILE="envs/${ENV}.tfvars"

# 检查 tfvars 文件是否存在
if [ ! -f "$TFVARS_FILE" ]; then
    log_error "配置文件不存在: $TFVARS_FILE"
    exit 1
fi

log_info "环境: $ENV"
log_info "操作: $ACTION"
log_info "配置文件: $TFVARS_FILE"

# 初始化 Terraform（如果需要）
if [ ! -d ".terraform" ]; then
    log_info "初始化 Terraform..."
    terraform init -backend-config=backend.hcl
fi

# 检查或创建 Workspace
CURRENT_WORKSPACE=$(terraform workspace show 2>/dev/null || echo "default")
if [ "$CURRENT_WORKSPACE" != "$ENV" ]; then
    log_info "切换到 workspace: $ENV"
    terraform workspace select "$ENV" 2>/dev/null || terraform workspace new "$ENV"
else
    log_info "当前 workspace: $ENV"
fi

# 执行 Terraform 操作
case $ACTION in
    plan)
        log_info "生成执行计划..."
        terraform plan -var-file="$TFVARS_FILE" -out="${ENV}.tfplan"
        log_success "执行计划已生成: ${ENV}.tfplan"
        log_info "运行 './deploy.sh $ENV apply' 来应用此计划"
        ;;
    
    apply)
        if [ -f "${ENV}.tfplan" ]; then
            log_info "应用执行计划..."
            terraform apply "${ENV}.tfplan"
            rm -f "${ENV}.tfplan"
            log_success "$ENV 环境部署成功！"
        else
            log_warning "未找到执行计划文件，直接应用..."
            terraform apply -var-file="$TFVARS_FILE" -auto-approve
            log_success "$ENV 环境部署成功！"
        fi
        
        # 显示输出
        log_info "部署输出："
        terraform output
        ;;
    
    destroy)
        log_warning "即将销毁 $ENV 环境的所有资源！"
        read -p "确认销毁吗？(yes/no): " -r
        if [ "$REPLY" = "yes" ]; then
            terraform destroy -var-file="$TFVARS_FILE" -auto-approve
            log_success "$ENV 环境已销毁"
        else
            log_info "取消销毁操作"
        fi
        ;;
esac

