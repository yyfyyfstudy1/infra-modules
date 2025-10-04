#!/bin/bash
# Jenkins 手动修复脚本

export AWS_PROFILE=dev-account
INSTANCE_ID="i-0557d2eb3444d8d59"

echo "=================================="
echo "🔧 Jenkins 手动修复"
echo "=================================="
echo ""

echo "📋 当前状态检查..."
echo ""

# 1. 检查实例状态
echo "1️⃣ 实例状态："
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,LaunchTime]' \
    --output table

echo ""

# 2. 检查健康状态
echo "2️⃣ ALB 健康检查："
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-2:859525219186:targetgroup/chime-mvp-cicd-tg/a63ffa4ed387de03 \
    --profile dev-account \
    --query 'TargetHealthDescriptions[0].TargetHealth' \
    --output table

echo ""

# 3. 检查安全组
echo "3️⃣ 安全组配置："
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].SecurityGroups[*].[GroupId,GroupName]' \
    --output table

echo ""

# 4. 检查目标组配置
echo "4️⃣ 目标组健康检查配置："
aws elbv2 describe-target-groups \
    --target-group-arns arn:aws:elasticloadbalancing:ap-southeast-2:859525219186:targetgroup/chime-mvp-cicd-tg/a63ffa4ed387de03 \
    --profile dev-account \
    --query 'TargetGroups[0].HealthCheck' \
    --output table

echo ""

# 5. 手动测试连接
echo "5️⃣ 尝试手动测试连接..."
echo ""

# 获取私有 IP
PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "私有 IP: $PRIVATE_IP"
echo ""

# 尝试从 ALB 子网测试连接
echo "尝试从 ALB 子网测试到 Jenkins 的连接..."

# 创建一个临时的测试实例来测试连接
echo "创建临时测试实例..."

# 获取 ALB 子网
ALB_SUBNET=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns arn:aws:elasticloadbalancing:ap-southeast-2:859525219186:loadbalancer/app/chime-mvp-cicd-alb/349c18a4b85f747a \
    --profile dev-account \
    --query 'LoadBalancers[0].AvailabilityZones[0].SubnetId' \
    --output text)

echo "ALB 子网: $ALB_SUBNET"
echo ""

# 6. 建议的修复步骤
echo "=================================="
echo "🔧 建议的修复步骤"
echo "=================================="
echo ""

echo "基于当前状态，建议执行以下步骤："
echo ""

echo "方案 1: 等待更长时间（推荐）"
echo "- Jenkins 首次安装需要 5-10 分钟"
echo "- 等待 10 分钟后再次检查"
echo ""

echo "方案 2: 手动修复（如果需要）"
echo "- 使用 EC2 Instance Connect 或 SSH 连接到实例"
echo "- 手动执行安装脚本"
echo ""

echo "方案 3: 重建实例（最后手段）"
echo "- 删除当前实例"
echo "- 重新创建"
echo ""

echo "当前时间: $(date)"
echo "实例启动时间: $(aws ec2 describe-instances --instance-ids $INSTANCE_ID --profile dev-account --query 'Reservations[0].Instances[0].LaunchTime' --output text)"
echo ""

# 计算运行时间
LAUNCH_TIME=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].LaunchTime' \
    --output text)

if [ ! -z "$LAUNCH_TIME" ]; then
    echo "实例已运行时间: $(date -d "$LAUNCH_TIME" +%s) 秒"
fi

echo ""
echo "💡 如果超过 10 分钟还是 unhealthy，请考虑重建实例"
echo ""
echo "重建命令："
echo "cd /Users/mt/infra-modules/infra/envs/cicd"
echo "terraform taint module.jenkins_ec2.aws_instance.jenkins"
echo "terraform apply -var-file=cicd.tfvars"
