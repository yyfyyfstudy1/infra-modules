# IAM role for Lambda
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  tags               = var.tags
}

# 基础执行策略（日志）
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# 附加额外的策略
resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = toset(var.iam_policies)
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

# 自定义策略（如果提供）
resource "aws_iam_policy" "custom" {
  count  = var.custom_policy_json != null ? 1 : 0
  name   = "${var.function_name}-custom"
  policy = var.custom_policy_json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  count      = var.custom_policy_json != null ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.custom[0].arn
}

# Lambda function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_role.arn
  filename      = var.lambda_zip_path
  handler       = var.handler
  runtime       = var.runtime
  architectures = var.architectures
  timeout       = var.timeout
  memory_size   = var.memory_size

  environment {
    variables = var.env_vars
  }

  tags = var.tags
}

