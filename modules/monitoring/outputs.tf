output "sns_topic_arn" {
  description = "ARN of the SNS topic used for service alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic used for service alerts"
  value       = aws_sns_topic.alerts.name
}

output "cpu_alarm_arn" {
  description = "ARN of the ECS CPU CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu_high.arn
}

output "memory_alarm_arn" {
  description = "ARN of the ECS memory CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory_high.arn
}

output "unhealthy_hosts_alarm_arn" {
  description = "ARN of the ALB unhealthy host CloudWatch alarm"
  value       = aws_cloudwatch_metric_alarm.alb_unhealthy_hosts.arn
}