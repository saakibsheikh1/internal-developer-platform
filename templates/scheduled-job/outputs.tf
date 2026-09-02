output "ecs_cluster_name" {
  description = "Scheduled job ECS cluster name"
  value       = module.scheduled_job.ecs_cluster_name
}

output "task_definition_arn" {
  description = "Scheduled job task definition ARN"
  value       = module.scheduled_job.task_definition_arn
}

output "schedule_name" {
  description = "EventBridge Scheduler schedule name"
  value       = module.scheduled_job.schedule_name
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = module.scheduled_job.log_group_name
}