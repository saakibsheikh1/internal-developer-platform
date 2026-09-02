resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.job_name}-${var.environment}-scheduled-job"
  retention_in_days = 7

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled-job"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.job_name}-${var.environment}-scheduled-cluster"

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled-cluster"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

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

  tags = {
    Name        = "${var.job_name}-${var.environment}-scheduled"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

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

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.job_name}-${var.environment}-scheduler-policy"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
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
    }]
  })
}

resource "aws_iam_role_policy" "pass_role" {
  name = "${var.job_name}-${var.environment}-scheduler-pass-role"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "iam:PassRole"
      ]

      Resource = aws_iam_role.execution.arn
    }]
  })
}

resource "aws_scheduler_schedule" "this" {
  name                         = "${var.job_name}-${var.environment}"
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = "Asia/Kolkata"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_ecs_cluster.this.arn
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.this.arn
      launch_type         = "FARGATE"

      network_configuration {
        subnets         = var.private_subnet_ids
        security_groups = [aws_security_group.this.id]

        assign_public_ip = false
      }
    }
  }
}