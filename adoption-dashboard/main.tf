terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket       = "sakib-terraform-state-495278513365"
    key          = "idp-onboarding/adoption-dashboard/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

locals {
  catalogue_bucket_name = var.catalogue_bucket_name != "" ? var.catalogue_bucket_name : "idp-platform-metrics-${data.aws_caller_identity.current.account_id}"
}

# ------------------------------------------------------------
# Lambda package
# ------------------------------------------------------------

data "archive_file" "platform_metrics" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/platform-metrics.zip"
}

# ------------------------------------------------------------
# Dedicated catalogue bucket
# ------------------------------------------------------------

resource "aws_s3_bucket" "catalogue" {
  bucket = local.catalogue_bucket_name

  tags = {
    Name        = local.catalogue_bucket_name
    ManagedBy   = "IDP"
    Purpose     = "PlatformCatalogueMetrics"
    Environment = "platform"
  }
}

resource "aws_s3_bucket_public_access_block" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "catalogue" {
  bucket = aws_s3_bucket.catalogue.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "catalogue_data" {
  bucket = aws_s3_bucket.catalogue.id
  key    = "catalogue/services.json"
  source = "${path.module}/catalogue-data/services.json"

  content_type = "application/json"

  etag = filemd5("${path.module}/catalogue-data/services.json")
}

# ------------------------------------------------------------
# IAM role for Platform Metrics Lambda
# ------------------------------------------------------------

resource "aws_iam_role" "platform_metrics" {
  name = "IDP-Platform-Metrics-Lambda"

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
    Name      = "IDP-Platform-Metrics-Lambda"
    ManagedBy = "IDP"
    Purpose   = "PlatformHealthMetrics"
  }
}

# ------------------------------------------------------------
# Lambda permissions
# ------------------------------------------------------------

resource "aws_iam_role_policy" "platform_metrics" {
  name = "IDP-Platform-Metrics-Lambda-Policy"
  role = aws_iam_role.platform_metrics.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "*"
      },

      {
        Sid    = "PublishMetrics"
        Effect = "Allow"

        Action = [
          "cloudwatch:PutMetricData"
        ]

        Resource = "*"
      },

      {
        Sid    = "ReadCatalogue"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.catalogue.arn}/catalogue/*"
      },

      {
        Sid    = "ListCatalogueBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = aws_s3_bucket.catalogue.arn
      },

      {
        Sid    = "ReadECS"
        Effect = "Allow"

        Action = [
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:ListTagsForResource"
        ]

        Resource = "*"
      },

      {
        Sid    = "PublishPlatformAlerts"
        Effect = "Allow"

        Action = [
          "sns:Publish"
        ]

        Resource = aws_sns_topic.platform_alerts.arn
      }
    ]
  })
}

# ------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "platform_metrics" {
  name              = "/aws/lambda/idp-platform-metrics"
  retention_in_days = 30

  tags = {
    Name      = "idp-platform-metrics"
    ManagedBy = "IDP"
  }
}

# ------------------------------------------------------------
# Platform Metrics Lambda
# ------------------------------------------------------------

resource "aws_lambda_function" "platform_metrics" {
  function_name = "idp-platform-metrics"

  role = aws_iam_role.platform_metrics.arn

  filename         = data.archive_file.platform_metrics.output_path
  source_code_hash = data.archive_file.platform_metrics.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"
  timeout = 60

  environment {
    variables = {
      METRICS_NAMESPACE    = var.metrics_namespace
      CATALOGUE_BUCKET     = aws_s3_bucket.catalogue.bucket
      ECS_CLUSTER          = var.ecs_cluster_name
      PLATFORM_ALERT_TOPIC = aws_sns_topic.platform_alerts.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.platform_metrics,
    aws_s3_object.catalogue_data
  ]

  tags = {
    Name      = "idp-platform-metrics"
    ManagedBy = "IDP"
    Purpose   = "PlatformHealthMetrics"
  }
}

# ------------------------------------------------------------
# EventBridge daily schedule
# ------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "daily_metrics" {
  name                = "idp-platform-metrics-daily"
  description         = "Runs the IDP platform metrics Lambda daily"
  schedule_expression = var.schedule_expression

  tags = {
    Name      = "idp-platform-metrics-daily"
    ManagedBy = "IDP"
  }
}

resource "aws_cloudwatch_event_target" "daily_metrics" {
  rule = aws_cloudwatch_event_rule.daily_metrics.name
  arn  = aws_lambda_function.platform_metrics.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeDailyMetrics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.platform_metrics.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_metrics.arn
}

# ------------------------------------------------------------
# SNS topic for platform alerts
# ------------------------------------------------------------

resource "aws_sns_topic" "platform_alerts" {
  name = "idp-platform-alerts"

  tags = {
    Name      = "idp-platform-alerts"
    ManagedBy = "IDP"
    Purpose   = "PlatformHealthAlerts"
  }
}

resource "aws_sns_topic_subscription" "platform_alert_email" {
  topic_arn = aws_sns_topic.platform_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ------------------------------------------------------------
# Alarm 1: onboarding pipeline failure
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "onboarding_failure" {
  alarm_name          = "idp-onboarding-pipeline-failure"
  alarm_description   = "An IDP onboarding pipeline failure was reported."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1

  metric_name = "OnboardingPipelineFailure"
  namespace   = var.metrics_namespace

  period    = 300
  statistic = "Sum"
  threshold = 0

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = {
    Name      = "idp-onboarding-pipeline-failure"
    ManagedBy = "IDP"
  }
}

# ------------------------------------------------------------
# Alarm 2: unregistered ECS service
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "unregistered_service" {
  alarm_name          = "idp-unregistered-service-detected"
  alarm_description   = "An ECS service is not registered in the IDP catalogue."
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1

  metric_name = "UnregisteredServices"
  namespace   = var.metrics_namespace

  period    = 86400
  statistic = "Maximum"
  threshold = 0

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = {
    Name      = "idp-unregistered-service-detected"
    ManagedBy = "IDP"
  }
}

# ------------------------------------------------------------
# Alarm 3: golden path compliance below 90%
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "golden_path_compliance" {
  alarm_name          = "idp-golden-path-compliance-below-90"
  alarm_description   = "Golden path compliance has dropped below 90%."
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1

  metric_name = "GoldenPathComplianceRate"
  namespace   = var.metrics_namespace

  period    = 86400
  statistic = "Minimum"
  threshold = 90

  treat_missing_data = "notBreaching"

  alarm_actions = [
    aws_sns_topic.platform_alerts.arn
  ]

  tags = {
    Name      = "idp-golden-path-compliance-below-90"
    ManagedBy = "IDP"
  }
}

# ------------------------------------------------------------
# CloudWatch Dashboard
# ------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "platform_health" {
  dashboard_name = "IDP-Platform-Health"

  dashboard_body = jsonencode({
    widgets = [

      # --------------------------------------------------------
      # Adoption
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Services Onboarded - Cumulative"
          region = var.aws_region
          stat   = "Maximum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "ServicesOnboardedCumulative"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Services Onboarded Per Week"
          region = var.aws_region
          stat   = "Sum"
          period = 604800

          metrics = [
            [
              var.metrics_namespace,
              "ServicesOnboardedPerWeek"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Deployment performance
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Time To Deploy P50"
          region = var.aws_region
          stat   = "Average"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "TimeToDeployP50",
              "TemplateType",
              "web-service"
            ],
            [
              var.metrics_namespace,
              "TimeToDeployP50",
              "TemplateType",
              "background-worker"
            ],
            [
              var.metrics_namespace,
              "TimeToDeployP50",
              "TemplateType",
              "scheduled-job"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Time To Deploy P99"
          region = var.aws_region
          stat   = "Average"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "TimeToDeployP99",
              "TemplateType",
              "web-service"
            ],
            [
              var.metrics_namespace,
              "TimeToDeployP99",
              "TemplateType",
              "background-worker"
            ],
            [
              var.metrics_namespace,
              "TimeToDeployP99",
              "TemplateType",
              "scheduled-job"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "Average Time To Deploy"
          region = var.aws_region
          stat   = "Average"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "AverageTimeToDeploy",
              "TemplateType",
              "web-service"
            ],
            [
              var.metrics_namespace,
              "AverageTimeToDeploy",
              "TemplateType",
              "background-worker"
            ],
            [
              var.metrics_namespace,
              "AverageTimeToDeploy",
              "TemplateType",
              "scheduled-job"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "Deployments Per Day"
          region = var.aws_region
          stat   = "Sum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "DeploymentsPerDay"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Golden path compliance
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          title  = "Golden Path Compliance"
          region = var.aws_region
          stat   = "Minimum"
          period = 86400

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }

          metrics = [
            [
              var.metrics_namespace,
              "GoldenPathComplianceRate"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Catalogue completeness
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6

        properties = {
          title  = "Catalogue Completeness"
          region = var.aws_region
          stat   = "Minimum"
          period = 86400

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }

          metrics = [
            [
              var.metrics_namespace,
              "CatalogueCompletenessRate"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Template adoption
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "Template Usage"
          region = var.aws_region
          stat   = "Maximum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "TemplateUsage",
              "TemplateType",
              "web-service"
            ],
            [
              var.metrics_namespace,
              "TemplateUsage",
              "TemplateType",
              "background-worker"
            ],
            [
              var.metrics_namespace,
              "TemplateUsage",
              "TemplateType",
              "scheduled-job"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Template version distribution
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "Template Version Distribution"
          region = var.aws_region
          stat   = "Maximum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "TemplateVersionDistribution",
              "TemplateVersion",
              "1.0.0"
            ]
          ]
        }
      },

      # --------------------------------------------------------
      # Platform health
      # --------------------------------------------------------

      {
        type   = "metric"
        x      = 0
        y      = 30
        width  = 12
        height = 6

        properties = {
          title  = "Unregistered Services"
          region = var.aws_region
          stat   = "Maximum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "UnregisteredServices"
            ]
          ]
        }
      },

      {
        type   = "metric"
        x      = 12
        y      = 30
        width  = 12
        height = 6

        properties = {
          title  = "Onboarding Pipeline Failures"
          region = var.aws_region
          stat   = "Sum"
          period = 86400

          metrics = [
            [
              var.metrics_namespace,
              "OnboardingPipelineFailure"
            ]
          ]
        }
      }
    ]
  })
}