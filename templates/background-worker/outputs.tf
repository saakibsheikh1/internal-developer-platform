output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.background_worker.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.background_worker.ecs_service_name
}

output "queue_url" {
  description = "SQS queue URL"
  value       = module.background_worker.queue_url
}

output "dlq_url" {
  description = "SQS dead letter queue URL"
  value       = module.background_worker.dlq_url
}