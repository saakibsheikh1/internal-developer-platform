# ------------------------------------------------------------
# CloudWatch Log Group - Scheduled Job Execution History
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "this" {
  name              = "/idp/${var.job_name}-${var.environment}/scheduled-job"
  retention_in_days = 7

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled-job"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# SQS Dead Letter Queue
# ------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.job_name}-${var.environment}-dlq"
  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.job_name}-${var.environment}-dlq"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ECS Cluster
# ------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.job_name}-${var.environment}-scheduled-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled-cluster"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# IAM Role - ECS Task Execution
# ------------------------------------------------------------

resource "aws_iam_role" "execution" {
  name = "${var.job_name}-${var.environment}-scheduled-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------
# Security Group - Scheduled ECS Task
# ------------------------------------------------------------

resource "aws_security_group" "this" {
  name        = "${var.job_name}-${var.environment}-scheduled-sg"
  description = "Security group for scheduled ECS job"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled-sg"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ECS Task Definition
# ------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.job_name}-${var.environment}-scheduled"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = var.job_name
      image     = var.docker_image
      essential = true

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "scheduled"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# Lambda Deployment Package
# ------------------------------------------------------------

resource "aws_lambda_function" "launcher" {
  function_name = "${var.job_name}-${var.environment}-launcher"

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  role    = aws_iam_role.lambda.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.12"

  timeout     = 60
  memory_size = 256

  environment {
    variables = {
      ECS_CLUSTER_ARN     = aws_ecs_cluster.this.arn
      TASK_DEFINITION_ARN = aws_ecs_task_definition.this.arn
      SUBNET_IDS          = join(",", var.private_subnet_ids)
      SECURITY_GROUP_ID   = aws_security_group.this.id
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this
  ]

  tags = {
    Name        = "${var.job_name}-${var.environment}-launcher"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# IAM Role - Lambda
# ------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.job_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "lambda.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# IAM Policy - Lambda Execution Logs
# ------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------------------------------------
# IAM Policy - Lambda Run ECS Task
# ------------------------------------------------------------

resource "aws_iam_role_policy" "lambda_ecs" {
  name = "${var.job_name}-${var.environment}-lambda-ecs-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "ecs:RunTask"
        ]

        Resource = aws_ecs_task_definition.this.arn

        Condition = {
          ArnEquals = {
            "ecs:cluster" = aws_ecs_cluster.this.arn
          }
        }
      },
      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.execution.arn
      }
    ]
  })
}

# ------------------------------------------------------------
# EventBridge Scheduler IAM Role
# ------------------------------------------------------------

resource "aws_iam_role" "scheduler" {
  name = "${var.job_name}-${var.environment}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "scheduler.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# EventBridge Scheduler -> Lambda Permission
# ------------------------------------------------------------

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.job_name}-${var.environment}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "lambda:InvokeFunction"
        ]

        Resource = aws_lambda_function.launcher.arn
      }
    ]
  })
}

# ------------------------------------------------------------
# EventBridge Scheduler
# ------------------------------------------------------------

resource "aws_scheduler_schedule" "this" {
  name                         = "${var.job_name}-${var.environment}"
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Kolkata"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.launcher.arn
    role_arn = aws_iam_role.scheduler.arn

    retry_policy {
      maximum_event_age_in_seconds = 86400
      maximum_retry_attempts       = 3
    }

    dead_letter_config {
      arn = aws_sqs_queue.dlq.arn
    }

    input = jsonencode({
      source      = "idp-scheduled-job"
      job_name    = var.job_name
      environment = var.environment
    })
  }
}