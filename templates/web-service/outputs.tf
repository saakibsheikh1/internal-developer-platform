# ------------------------------------------------------------
# ECS Outputs
# ------------------------------------------------------------

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.web_service.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.web_service.ecs_service_name
}

# ------------------------------------------------------------
# Load Balancer Outputs
# ------------------------------------------------------------

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.web_service.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer"
  value       = module.web_service.load_balancer_zone_id
}

# ------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.web_service.cloudwatch_log_group_name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for service alerts"
  value       = module.monitoring.sns_topic_arn
}

output "sns_topic_name" {
  description = "SNS topic name for service alerts"
  value       = module.monitoring.sns_topic_name
}

output "cpu_alarm_arn" {
  description = "ARN of the ECS CPU CloudWatch alarm"
  value       = module.monitoring.cpu_alarm_arn
}

output "memory_alarm_arn" {
  description = "ARN of the ECS memory CloudWatch alarm"
  value       = module.monitoring.memory_alarm_arn
}

output "unhealthy_hosts_alarm_arn" {
  description = "ARN of the ALB unhealthy host CloudWatch alarm"
  value       = module.monitoring.unhealthy_hosts_alarm_arn
}

# ------------------------------------------------------------
# Optional Route53 Output
# ------------------------------------------------------------

output "route53_record_name" {
  description = "Route53 record name when configured"
  value       = var.route53_record_name
}