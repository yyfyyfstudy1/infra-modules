# 在 Test 账户中创建此角色
# 使用方法: 在 test 账户执行 terraform apply

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-2"
  profile = "test-account"
}

# 获取 dev 账户的 Jenkins 实例角色（需要手动填写 ARN）
variable "jenkins_role_arn" {
  description = "Dev 账户中 Jenkins EC2 实例角色 ARN"
  type        = string
  # 示例：arn:aws:iam::859525219186:role/chime-mvp-cicd-jenkins-role
}

# Jenkins 部署角色
resource "aws_iam_role" "jenkins_deployer" {
  name = "JenkinsDeployerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.jenkins_role_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "jenkins-deployer"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "JenkinsDeployerRole"
    Environment = "test"
    ManagedBy   = "Terraform"
  }
}

# 部署权限策略（最小权限版本）
resource "aws_iam_role_policy" "jenkins_deployer" {
  name = "JenkinsDeployerPolicy"
  role = aws_iam_role.jenkins_deployer.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Lambda 权限
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:GetFunction",
          "lambda:DeleteFunction",
          "lambda:PublishVersion",
          "lambda:CreateAlias",
          "lambda:UpdateAlias",
          "lambda:GetFunctionConfiguration",
          "lambda:ListVersionsByFunction",
          "lambda:AddPermission",
          "lambda:RemovePermission"
        ]
        Resource = "arn:aws:lambda:ap-southeast-2:*:function:chime-mvp-test-*"
      },
      # IAM 权限（Lambda 角色）
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:PassRole"
        ]
        Resource = "arn:aws:iam::*:role/chime-mvp-test-*"
      },
      # API Gateway 权限
      {
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "arn:aws:apigateway:ap-southeast-2::*"
      },
      # S3 权限（制品和 Terraform state）
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::chime-mvp-tfstate-test-syd",
          "arn:aws:s3:::chime-mvp-tfstate-test-syd/*",
          "arn:aws:s3:::chime-mvp-test-*",
          "arn:aws:s3:::chime-mvp-test-*/*"
        ]
      },
      # DynamoDB 权限（Terraform state lock）
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:ap-southeast-2:*:table/tfstate-lock-test"
      },
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:ap-southeast-2:*:log-group:/aws/lambda/chime-mvp-test-*"
      }
    ]
  })
}

output "role_arn" {
  description = "Jenkins 部署角色 ARN"
  value       = aws_iam_role.jenkins_deployer.arn
}

