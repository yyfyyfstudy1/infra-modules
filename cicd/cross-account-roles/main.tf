terraform {
  # 使用本地 state；根据需要可接入远端 backend
}

locals {
  role_name = var.role_name
  tags = merge({
    ManagedBy = "Terraform"
    Purpose   = "Jenkins-Deploy-Role"
  }, var.tags)
}

data "aws_caller_identity" "current" {}

# 供可读性使用：当前账户 ID
locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Jenkins 在 Dev 账户的实例角色 ARN 作为可信主体
data "aws_iam_policy_document" "assume_from_jenkins" {
  statement {
    sid     = "AllowAssumeFromJenkins"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.jenkins_role_arn]
    }
  }
}

resource "aws_iam_role" "jenkins_deployer" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_from_jenkins.json
  tags               = local.tags
}

# 为简化演示，授予 AdministratorAccess（可按需改为最小权限）
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.jenkins_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


