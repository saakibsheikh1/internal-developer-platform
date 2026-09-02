output "ecs_cluster_name" {
  description = "Scheduled job ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Scheduled job task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

output "schedule_name" {
  description = "EventBridge Scheduler schedule name"
  value       = aws_scheduler_schedule.this.name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.this.name
}