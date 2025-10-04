#!/bin/bash
# 测试 Jenkins 连接的脚本

export AWS_PROFILE=dev-account

echo "=================================="
echo "🔍 Jenkins 连接测试"
echo "=================================="
echo ""

# 获取实例信息
INSTANCE_ID="i-0f0abcdd0e60739d1"
PRIVATE_IP="10.0.10.195"

echo "📋 实例信息："
echo "Instance ID: $INSTANCE_ID"
echo "Private IP: $PRIVATE_IP"
echo ""

# 1. 检查实例状态
echo "1️⃣ 检查实例状态..."
aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].[InstanceId,State.Name,LaunchTime]' \
    --output table

echo ""

# 2. 检查健康状态
echo "2️⃣ 检查 ALB 健康状态..."
aws elbv2 describe-target-health \
    --target-group-arn arn:aws:elasticloadbalancing:ap-southeast-2:859525219186:targetgroup/chime-mvp-cicd-tg/a63ffa4ed387de03 \
    --profile dev-account \
    --query 'TargetHealthDescriptions[0].TargetHealth' \
    --output table

echo ""

# 3. 检查安全组
echo "3️⃣ 检查安全组..."
SG_ID=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --profile dev-account \
    --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId' \
    --output text)

echo "Security Group ID: $SG_ID"

aws ec2 describe-security-groups \
    --group-ids $SG_ID \
    --profile dev-account \
    --query 'SecurityGroups[0].IpPermissions[*].[IpProtocol,FromPort,ToPort,UserIdGroupPairs[0].GroupId]' \
    --output table

echo ""

# 4. 尝试从 ALB 子网测试连接
echo "4️⃣ 尝试测试连接..."

# 获取 ALB 子网
ALB_SUBNET=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns arn:aws:elasticloadbalancing:ap-southeast-2:859525219186:loadbalancer/app/chime-mvp-cicd-alb/349c18a4b85f747a \
    --profile dev-account \
    --query 'LoadBalancers[0].AvailabilityZones[0].SubnetId' \
    --output text)

echo "ALB Subnet: $ALB_SUBNET"

# 创建一个临时的测试实例来测试连接
echo "创建临时测试实例..."

# 获取最新的 Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-*-x86_64" "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text \
    --profile dev-account)

echo "Using AMI: $AMI_ID"

# 创建临时实例
TEMP_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t3.micro \
    --subnet-id $ALB_SUBNET \
    --security-group-ids $SG_ID \
    --user-data '#!/bin/bash
echo "Testing connection to Jenkins..."
sleep 30
curl -I http://'$PRIVATE_IP':8080 || echo "Connection failed"
curl -I http://'$PRIVATE_IP':8080/login || echo "Login path failed"
echo "Test completed"' \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=jenkins-test}]' \
    --query 'Instances[0].InstanceId' \
    --output text \
    --profile dev-account)

echo "Created test instance: $TEMP_INSTANCE_ID"

echo ""
echo "等待测试实例启动并执行测试..."
sleep 60

# 获取测试实例的日志
echo "测试结果："
aws ec2 get-console-output \
    --instance-id $TEMP_INSTANCE_ID \
    --profile dev-account \
    --query 'Output' \
    --output text | tail -20

echo ""

# 清理测试实例
echo "清理测试实例..."
aws ec2 terminate-instances \
    --instance-ids $TEMP_INSTANCE_ID \
    --profile dev-account >/dev/null

echo "测试完成！"

echo ""
echo "=================================="
echo "📊 诊断结果"
echo "=================================="
echo ""

echo "如果测试显示连接失败，可能的原因："
echo "1. Jenkins 服务没有启动"
echo "2. 端口 8080 没有监听"
echo "3. User Data 脚本执行失败"
echo "4. EBS 挂载失败"
echo ""
echo "建议下一步："
echo "1. 检查实例的 User Data 执行日志"
echo "2. 手动连接到实例检查 Jenkins 状态"
echo "3. 重建实例"
