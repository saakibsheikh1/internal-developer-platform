# ============================================================
# Dead Letter Queue
# ============================================================

resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name}-dlq"

  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.queue_name}-dlq"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# Main SQS Queue
# ============================================================

resource "aws_sqs_queue" "this" {
  name = var.queue_name

  visibility_timeout_seconds = var.visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name        = var.queue_name
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# ECS Cluster
# ============================================================

resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-${var.environment}-worker-cluster"

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-cluster"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# IAM Role - ECS Task Execution
# ============================================================

resource "aws_iam_role" "ecs_execution" {
  name = "${var.service_name}-${var.environment}-worker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-execution-role"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ============================================================
# IAM Role - Worker Task
# ============================================================

resource "aws_iam_role" "worker_task" {
  name = "${var.service_name}-${var.environment}-worker-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-task-role"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# IAM Policy - SQS Access
# ============================================================

resource "aws_iam_role_policy" "worker_sqs" {
  name = "${var.service_name}-${var.environment}-worker-sqs-policy"
  role = aws_iam_role.worker_task.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]

        Resource = aws_sqs_queue.this.arn
      }
    ]
  })
}

# ============================================================
# CloudWatch Log Group
# ============================================================

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.service_name}-${var.environment}-worker"
  retention_in_days = 7

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-logs"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# ECS Task Definition
# ============================================================

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.worker_task.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.docker_image
      essential = true

      environment = [
        {
          name  = "QUEUE_URL"
          value = aws_sqs_queue.this.url
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "worker"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-task"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# ECS Security Group
# ============================================================

resource "aws_security_group" "worker" {
  name        = "${var.service_name}-${var.environment}-worker-sg"
  description = "Security group for ECS background worker"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-sg"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# ECS Worker Service
# ============================================================

resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}-worker-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.worker.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-service"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ============================================================
# Application Auto Scaling - ECS
# ============================================================

resource "aws_appautoscaling_target" "worker" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ============================================================
# Auto Scaling - Queue Depth
# ============================================================

resource "aws_appautoscaling_policy" "queue_depth" {
  name               = "${var.service_name}-${var.environment}-queue-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker.resource_id
  scalable_dimension = aws_appautoscaling_target.worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 10

    customized_metric_specification {
      namespace   = "AWS/SQS"
      metric_name = "ApproximateNumberOfMessagesVisible"
      statistic   = "Average"

      dimensions {
        name  = "QueueName"
        value = aws_sqs_queue.this.name
      }
    }

    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# ============================================================
# CloudWatch Alarm - Queue Backlog
# ============================================================

resource "aws_cloudwatch_metric_alarm" "queue_backlog" {
  alarm_name          = "${var.service_name}-${var.environment}-worker-queue-backlog"
  alarm_description   = "Worker queue has a high number of visible messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 100
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-worker-queue-backlog"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}