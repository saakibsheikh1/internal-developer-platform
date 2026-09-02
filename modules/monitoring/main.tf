# ------------------------------------------------------------
# SNS Topic
# ------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name = "${var.service_name}-${var.environment}-alerts"

  tags = {
    Name        = "${var.service_name}-${var.environment}-alerts"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# SNS Email Subscription
# ------------------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ------------------------------------------------------------
# ECS CPU Alarm
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.service_name}-${var.environment}-cpu-high"
  alarm_description   = "ECS CPU utilization is above the approved threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-cpu-high"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ECS Memory Alarm
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.service_name}-${var.environment}-memory-high"
  alarm_description   = "ECS memory utilization is above the approved threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "ECS/ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_alarm_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-memory-high"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}

# ------------------------------------------------------------
# ALB Unhealthy Host Alarm
# ------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${var.service_name}-${var.environment}-unhealthy-hosts"
  alarm_description   = "ALB has unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix
    LoadBalancer = var.load_balancer_arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  tags = {
    Name        = "${var.service_name}-${var.environment}-unhealthy-hosts"
    Team        = var.team_name
    Environment = var.environment
    ManagedBy   = "IDP"
  }
}