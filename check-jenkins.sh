#!/bin/bash
# Jenkins 快速健康检查

export AWS_PROFILE=dev-account
cd /Users/mt/infra-modules/infra/envs/cicd

echo "🔍 Jenkins 健康检查..."
echo ""

# 获取实例 ID
INSTANCE_ID=$(terraform output -raw jenkins_instance_id 2>/dev/null)

if [ -z "$INSTANCE_ID" ]; then
    echo "❌ 无法获取实例 ID"
    exit 1
fi

echo "📋 实例 ID: $INSTANCE_ID"
echo ""

# 检查目标组健康状态
echo "🏥 检查健康状态..."
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names chime-mvp-cicd-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --profile dev-account 2>/dev/null)

if [ ! -z "$TARGET_GROUP_ARN" ]; then
    HEALTH=$(aws elbv2 describe-target-health \
        --target-group-arn $TARGET_GROUP_ARN \
        --profile dev-account 2>/dev/null)
    
    STATE=$(echo "$HEALTH" | grep -o '"State": "[^"]*"' | head -1 | cut -d'"' -f4)
    REASON=$(echo "$HEALTH" | grep -o '"Reason": "[^"]*"' | head -1 | cut -d'"' -f4)
    
    echo "状态: $STATE"
    echo "原因: $REASON"
    echo ""
    
    if [ "$STATE" == "healthy" ]; then
        echo "✅ Jenkins 健康！"
        echo ""
        echo "访问: http://chime-mvp-cicd-alb-1146214425.ap-southeast-2.elb.amazonaws.com"
    else
        echo "❌ Jenkins 不健康"
        echo ""
        echo "💡 最可能的原因："
        echo "   1. Jenkins 还在启动（需要 3-5 分钟）"
        echo "   2. 端口 8080 未监听"
        echo ""
        echo "🔧 连接到实例检查："
        echo "   aws ssm start-session --target $INSTANCE_ID --profile dev-account --region ap-southeast-2"
        echo ""
        echo "   # 在实例内执行："
        echo "   sudo systemctl status jenkins"
        echo "   sudo journalctl -u jenkins -n 50 --no-pager"
        echo "   curl http://localhost:8080"
    fi
else
    echo "⚠️ 无法获取目标组信息"
fi

