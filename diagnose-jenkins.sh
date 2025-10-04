#!/bin/bash
# Jenkins 故障诊断脚本

set -e

echo "=================================="
echo "🔍 Jenkins 故障诊断"
echo "=================================="
echo ""

export AWS_PROFILE=dev-account
cd /Users/mt/infra-modules/infra/envs/cicd

# 获取输出
echo "📋 获取资源信息..."
INSTANCE_ID=$(terraform output -raw jenkins_instance_id 2>/dev/null)
ALB_ARN=$(terraform output -raw jenkins_alb_arn 2>/dev/null || echo "")
TARGET_GROUP_ARN=$(terraform output -raw jenkins_target_group_arn 2>/dev/null || echo "")

if [ -z "$INSTANCE_ID" ]; then
    echo "❌ 无法获取实例 ID"
    exit 1
fi

echo "✅ Instance ID: $INSTANCE_ID"
echo ""

# 1. 检查 EC2 实例状态
echo "=================================="
echo "1️⃣ 检查 EC2 实例状态"
echo "=================================="
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,PrivateIpAddress,PublicIpAddress]' \
    --output table \
    --profile dev-account

INSTANCE_STATE=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text \
    --profile dev-account)

if [ "$INSTANCE_STATE" != "running" ]; then
    echo "❌ 实例状态异常: $INSTANCE_STATE"
    exit 1
fi
echo "✅ 实例状态正常: running"
echo ""

# 2. 检查目标组健康状态
echo "=================================="
echo "2️⃣ 检查 ALB 目标组健康状态"
echo "=================================="

# 获取目标组 ARN
if [ -z "$TARGET_GROUP_ARN" ]; then
    echo "从 ALB 获取目标组..."
    ALB_NAME="chime-mvp-cicd-alb"
    TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
        --names chime-mvp-cicd-tg \
        --query 'TargetGroups[0].TargetGroupArn' \
        --output text \
        --profile dev-account 2>/dev/null || echo "")
fi

if [ ! -z "$TARGET_GROUP_ARN" ] && [ "$TARGET_GROUP_ARN" != "None" ]; then
    aws elbv2 describe-target-health \
        --target-group-arn $TARGET_GROUP_ARN \
        --profile dev-account \
        --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State,TargetHealth.Reason,TargetHealth.Description]' \
        --output table
    
    HEALTH_STATE=$(aws elbv2 describe-target-health \
        --target-group-arn $TARGET_GROUP_ARN \
        --profile dev-account \
        --query 'TargetHealthDescriptions[0].TargetHealth.State' \
        --output text)
    
    if [ "$HEALTH_STATE" != "healthy" ]; then
        echo "❌ 目标健康状态: $HEALTH_STATE"
        echo ""
        echo "常见原因："
        echo "  - Jenkins 服务还在启动中（需要 3-5 分钟）"
        echo "  - Jenkins 8080 端口未监听"
        echo "  - 安全组配置问题"
    else
        echo "✅ 目标健康状态: healthy"
    fi
else
    echo "⚠️  无法获取目标组 ARN"
fi
echo ""

# 3. 检查系统日志
echo "=================================="
echo "3️⃣ 检查 EC2 系统日志（最近 50 行）"
echo "=================================="
echo "正在获取系统日志..."
aws ec2 get-console-output \
    --instance-id $INSTANCE_ID \
    --profile dev-account \
    --query 'Output' \
    --output text 2>/dev/null | tail -50 || echo "⚠️  系统日志暂时无法获取"
echo ""

# 4. 检查安全组
echo "=================================="
echo "4️⃣ 检查安全组配置"
echo "=================================="
SG_IDS=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' \
    --output text \
    --profile dev-account)

for SG_ID in $SG_IDS; do
    echo "安全组: $SG_ID"
    aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --profile dev-account \
        --query 'SecurityGroups[0].[GroupName,GroupId]' \
        --output table
    
    echo "入站规则："
    aws ec2 describe-security-groups \
        --group-ids $SG_ID \
        --profile dev-account \
        --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' \
        --output table
    echo ""
done

# 5. 建议的检查命令
echo "=================================="
echo "5️⃣ 手动检查建议"
echo "=================================="
echo ""
echo "🔧 使用 SSM 连接到实例检查 Jenkins："
echo ""
echo "aws ssm start-session \\"
echo "  --target $INSTANCE_ID \\"
echo "  --profile dev-account \\"
echo "  --region ap-southeast-2"
echo ""
echo "# 进入实例后执行："
echo "sudo systemctl status jenkins"
echo "sudo journalctl -u jenkins -n 50"
echo "sudo netstat -tlnp | grep 8080"
echo "curl -I http://localhost:8080"
echo ""

# 6. 最可能的原因
echo "=================================="
echo "📊 诊断结果"
echo "=================================="
echo ""

if [ "$INSTANCE_STATE" == "running" ] && [ "$HEALTH_STATE" != "healthy" ]; then
    echo "❌ 实例运行中，但健康检查失败"
    echo ""
    echo "🔍 最可能的原因："
    echo ""
    echo "1️⃣  Jenkins 还在启动中（最常见）"
    echo "   - Jenkins 首次启动需要 3-5 分钟"
    echo "   - 建议等待 5 分钟后再次访问"
    echo ""
    echo "2️⃣  Jenkins 8080 端口未监听"
    echo "   - 检查命令: sudo netstat -tlnp | grep 8080"
    echo "   - 检查日志: sudo journalctl -u jenkins -n 100"
    echo ""
    echo "3️⃣  EBS 卷挂载失败"
    echo "   - 检查命令: df -h | grep jenkins"
    echo "   - 检查日志: sudo cat /var/log/cloud-init-output.log"
    echo ""
    echo "4️⃣  安全组配置问题"
    echo "   - 检查 ALB 安全组是否允许访问 Jenkins 8080"
    echo ""
elif [ "$HEALTH_STATE" == "healthy" ]; then
    echo "✅ 所有检查通过"
    echo ""
    echo "可能是临时问题，请重试访问："
    echo "http://chime-mvp-cicd-alb-1146214425.ap-southeast-2.elb.amazonaws.com"
else
    echo "⚠️  正在诊断中..."
fi

echo ""
echo "=================================="

