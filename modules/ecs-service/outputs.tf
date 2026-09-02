# ------------------------------------------------------------
# ECS Cluster Outputs
# ------------------------------------------------------------

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.this.id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

# ------------------------------------------------------------
# ECS Service Outputs
# ------------------------------------------------------------

output "ecs_service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.this.id
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ECS task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

# ------------------------------------------------------------
# Application Load Balancer Outputs
# ------------------------------------------------------------

output "load_balancer_id" {
  description = "Application Load Balancer ID"
  value       = aws_lb.this.id
}

output "load_balancer_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.this.arn
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

# ------------------------------------------------------------
# Target Group Outputs
# ------------------------------------------------------------

output "target_group_arn" {
  description = "ALB target group ARN"
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group"
  value       = aws_lb_target_group.this.arn_suffix
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix of the ALB"
  value       = aws_lb.this.arn_suffix
}

# ------------------------------------------------------------
# Security Group Outputs
# ------------------------------------------------------------

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = aws_security_group.ecs.id
}

# ------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.ecs.name
}