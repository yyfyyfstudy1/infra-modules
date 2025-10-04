terraform {
  backend "s3" {} # 使用 init -backend-config=backend.hcl 注入参数
}

# Chime IAM 策略文档
data "aws_iam_policy_document" "chime" {
  statement {
    effect = "Allow"
    actions = [
      "chime:CreateMeeting",
      "chime:CreateAttendee",
      "chime:GetMeeting",
      "chime:DeleteMeeting",
      "chime-sdk-meetings:CreateMeeting",
      "chime-sdk-meetings:CreateAttendee",
      "chime-sdk-meetings:GetMeeting",
      "chime-sdk-meetings:DeleteMeeting"
    ]
    resources = ["*"]
  }
}

# Lambda 函数 - Join
module "lambda_join" {
  source = "../../modules/lambda_app"

  function_name    = "${local.name_prefix}-join"
  handler          = "JoinFunction::JoinFunction.Function::FunctionHandler"
  runtime          = "dotnet8"
  architectures    = ["arm64"]
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  lambda_zip_path  = var.lambda_zip_path
  
  env_vars = {
    CHIME_CLIENT_REGION = var.chime_client_region
    MEDIA_REGION        = var.media_region
  }

  custom_policy_json = data.aws_iam_policy_document.chime.json
  tags               = local.common_tags
}

# API Gateway HTTP API
module "api_gateway" {
  source = "../../modules/apigw_http"

  api_name   = "${local.name_prefix}-api"
  stage_name = local.env

  routes = [
    {
      route_key   = "POST /join"
      lambda_arn  = module.lambda_join.invoke_arn
      lambda_name = module.lambda_join.function_name
    }
  ]

  cors_configuration = {
    allow_origins     = ["*"]
    allow_methods     = ["POST", "OPTIONS", "GET"]
    allow_headers     = ["content-type", "authorization", "x-amz-date", "x-api-key", "x-amz-security-token"]
    allow_credentials = false
    max_age           = 86400
  }

  tags = local.common_tags
}

# 测试用的 S3 桶 - 临时注释用于测试 GitOps 工作流
# module "test_bucket" {
#   source = "../../modules/s3_bucket"
#
#   bucket_name        = "${local.name_prefix}-test-bucket"
#   versioning_enabled = false
#   force_destroy      = true
#   tags               = local.common_tags
# }

# CI/CD 测试用的 S3 桶
module "test_cicd_bucket" {
  source = "../../modules/s3_bucket"

  bucket_name        = "test-cicd-${random_id.bucket_suffix.hex}"
  versioning_enabled = true
  force_destroy      = true
  tags = merge(local.common_tags, {
    Purpose = "CI/CD-Testing"
    CreatedBy = "Jenkins-Pipeline"
  })
}

# 生成随机后缀确保 bucket 名称唯一
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

