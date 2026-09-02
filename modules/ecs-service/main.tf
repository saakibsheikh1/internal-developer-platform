# ------------------------------------------------------------
# ECS Cluster
# ------------------------------------------------------------

resource "aws_ecs_cluster" "this" {
  name = "${var.service_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-cluster"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# IAM Role - ECS Task Execution
# ------------------------------------------------------------

resource "aws_iam_role" "ecs_execution" {
  name = "${var.service_name}-${var.environment}-ecs-execution-role"

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
    Name        = "${var.service_name}-${var.environment}-ecs-execution-role"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ------------------------------------------------------------
# Security Group - ALB
# ------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.service_name}-${var.environment}-alb-sg"
  description = "Security group for the application load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-alb-sg"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# Security Group - ECS Tasks
# ------------------------------------------------------------

resource "aws_security_group" "ecs" {
  name        = "${var.service_name}-${var.environment}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-ecs-sg"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------

resource "aws_lb" "this" {
  name               = "${var.service_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.service_name}-${var.environment}-alb"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# Target Group
# ------------------------------------------------------------

resource "aws_lb_target_group" "this" {
  name        = "${var.service_name}-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-tg"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ALB Listener
# ------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn = aws_lb_target_group.this.arn
      }
    }
  }

  tags = {
    Name        = "${var.service_name}-${var.environment}-http-listener"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# CloudWatch Log Group
# ------------------------------------------------------------

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.service_name}-${var.environment}-logs"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ECS Task Definition
# ------------------------------------------------------------

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = var.service_name
      image     = var.docker_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = "/ecs/${var.service_name}-${var.environment}"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [
    aws_cloudwatch_log_group.ecs
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-task"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ECS Service
# ------------------------------------------------------------

resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_execution
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-service"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}