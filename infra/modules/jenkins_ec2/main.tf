# 获取最新的 Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Jenkins 安全组（基础 - 不含互相引用的规则）
resource "aws_security_group" "jenkins" {
  name_prefix = "${var.name_prefix}-jenkins-"
  description = "Security group for Jenkins EC2"
  vpc_id      = var.vpc_id

  # 允许 SSH（可选，用于调试）
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow SSH from allowed IPs"
  }

  # 出站全开
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-sg"
    }
  )
}

# ALB 安全组（基础 - 不含互相引用的规则）
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  # HTTPS 访问
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTPS from allowed IPs"
  }

  # HTTP 访问（可选，用于重定向）
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Allow HTTP from allowed IPs"
  }

  # 出站全开（简化配置，避免循环依赖）
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}

# 安全组规则：允许 ALB 访问 Jenkins 8080
resource "aws_security_group_rule" "jenkins_from_alb_8080" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.jenkins.id
  description              = "Allow HTTP from ALB"
}

# 安全组规则：允许 ALB 访问 Jenkins 50000（Agent 端口）
resource "aws_security_group_rule" "jenkins_from_alb_50000" {
  type                     = "ingress"
  from_port                = 50000
  to_port                  = 50000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.jenkins.id
  description              = "Allow Jenkins agent from ALB"
}

# IAM 角色 - EC2 实例角色
resource "aws_iam_role" "jenkins" {
  name = "${var.name_prefix}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# IAM 策略 - 允许 AssumeRole 到 test/prod
resource "aws_iam_role_policy" "jenkins_assume_role" {
  name = "${var.name_prefix}-assume-role"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${var.test_account_id}:role/JenkinsDeployerRole",
          "arn:aws:iam::${var.prod_account_id}:role/JenkinsDeployerRole"
        ]
      }
    ]
  })
}

# IAM 策略 - CloudWatch Logs（可选）
resource "aws_iam_role_policy_attachment" "jenkins_cloudwatch" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# IAM 策略 - SSM（可选，用于 Session Manager）
resource "aws_iam_role_policy_attachment" "jenkins_ssm" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM 实例配置文件
resource "aws_iam_instance_profile" "jenkins" {
  name = "${var.name_prefix}-jenkins-profile"
  role = aws_iam_role.jenkins.name
}

# EBS 卷
resource "aws_ebs_volume" "jenkins" {
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = var.ebs_volume_size
  type              = "gp3"
  encrypted         = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins-data"
    }
  )
}

# 获取子网信息
data "aws_subnet" "selected" {
  id = var.subnet_id
}

# User Data 脚本
locals {
  user_data = <<-EOF
    #!/bin/bash
    set -e
    
    # 创建日志文件
    exec > >(tee /var/log/user-data.log) 2>&1
    echo "Starting Jenkins installation at $(date)"
    
    # 更新系统并安装必要工具
    dnf update -y
    # 解决 curl 包冲突，使用 --allowerasing 选项
    dnf install -y wget curl unzip --allowerasing
    
    # 安装 Java 17
    dnf install -y java-17-amazon-corretto
    
    # 安装 Jenkins
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    dnf install -y jenkins
    
    # 安装 Git 和 Docker
    dnf install -y git docker
    
    # 启动 Docker
    systemctl enable --now docker
    usermod -aG docker jenkins
    
    # 挂载 EBS 卷
    # 等待 EBS 卷附加并检测设备名称
    while true; do
      # 检查常见的 EBS 设备名称
      for device in /dev/nvme1n1 /dev/xvdf /dev/sdf; do
        if [ -e "$device" ] && ! mount | grep -q "$device"; then
          EBS_DEVICE="$device"
          break 2
        fi
      done
      sleep 2
    done
    
    echo "Found EBS device: $EBS_DEVICE"
    
    # 格式化并挂载
    if ! file -s "$EBS_DEVICE" | grep -q ext4; then
      echo "Formatting $EBS_DEVICE"
      mkfs -t ext4 "$EBS_DEVICE"
    fi
    
    mkdir -p /var/lib/jenkins
    mount "$EBS_DEVICE" /var/lib/jenkins
    echo "$EBS_DEVICE /var/lib/jenkins ext4 defaults,nofail 0 2" >> /etc/fstab
    chown -R jenkins:jenkins /var/lib/jenkins
    
    # 安装 Terraform
    wget https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip
    unzip terraform_1.9.0_linux_amd64.zip
    mv terraform /usr/local/bin/
    rm terraform_1.9.0_linux_amd64.zip
    
    # 安装 AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
    
    # 启动 Jenkins
    echo "Starting Jenkins service..."
    systemctl enable --now jenkins
    
    # 等待 Jenkins 启动
    echo "Waiting for Jenkins to start..."
    sleep 30
    
    # 检查 Jenkins 状态
    if systemctl is-active --quiet jenkins; then
      echo "Jenkins is running"
    else
      echo "Jenkins failed to start"
      systemctl status jenkins
    fi
    
    # 检查端口监听
    if netstat -tlnp | grep -q 8080; then
      echo "Jenkins is listening on port 8080"
    else
      echo "Jenkins is not listening on port 8080"
      netstat -tlnp
    fi
    
    # 输出初始密码
    echo "Jenkins initial password:"
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
      cat /var/lib/jenkins/secrets/initialAdminPassword
    else
      echo "Password file not found yet"
    fi
    
    echo "Jenkins installation completed at $(date)"
  EOF
}

# EC2 实例
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  iam_instance_profile   = aws_iam_instance_profile.jenkins.name
  key_name               = var.key_name != "" ? var.key_name : null

  user_data = local.user_data

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-jenkins"
    }
  )
}

# 附加 EBS 卷
resource "aws_volume_attachment" "jenkins" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.jenkins.id
  instance_id = aws_instance.jenkins.id
}

