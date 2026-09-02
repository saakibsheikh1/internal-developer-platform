terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  name_prefix = "${var.project_name}-orphan-detection"
}

resource "aws_s3_bucket" "catalogue" {
  bucket = var.catalogue_bucket_name

  tags = {
    Project     = var.project_name
    ManagedBy   = "IDP"
    Purpose     = "service-catalogue"
  }
}

resource "aws_s3_bucket_public_access_block" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id
  key    = var.catalogue_object_key

  content = jsonencode({
    services = [
      {
        name = "payment-api-dev-service"
      },
      {
        name = "order-processor-dev-worker-service"
      }
    ]
  })

  content_type = "application/json"

  depends_on = [
    aws_s3_bucket_public_access_block.catalogue
  ]
}

resource "aws_sns_topic" "orphan_alerts" {
  name = "${local.name_prefix}-alerts"

  tags = {
    Project   = var.project_name
    ManagedBy = "IDP"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.orphan_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project   = var.project_name
    ManagedBy = "IDP"
  }
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.catalogue.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.orphan_alerts.arn
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}"
  retention_in_days = 14

  tags = {
    Project   = var.project_name
    ManagedBy = "IDP"
  }
}

resource "aws_lambda_function" "orphan_detection" {
  function_name = local.name_prefix
  role          = aws_iam_role.lambda.arn

  runtime = "python3.12"
  handler = "lambda_function.lambda_handler"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      CATALOGUE_BUCKET = aws_s3_bucket.catalogue.bucket
      CATALOGUE_KEY    = var.catalogue_object_key
      SNS_TOPIC_ARN    = aws_sns_topic.orphan_alerts.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda,
    aws_iam_role_policy.lambda
  ]

  tags = {
    Project   = var.project_name
    ManagedBy = "IDP"
  }
}

resource "aws_cloudwatch_event_rule" "daily_audit" {
  name                = "${local.name_prefix}-daily"
  description         = "Daily ECS service catalogue orphan audit"
  schedule_expression = var.audit_schedule

  tags = {
    Project   = var.project_name
    ManagedBy = "IDP"
  }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.daily_audit.name
  arn  = aws_lambda_function.orphan_detection.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeDailyAudit"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orphan_detection.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_audit.arn
}
