output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.web_service.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.web_service.ecs_service_name
}

output "load_balancer_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.web_service.load_balancer_dns_name
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = module.web_service.cloudwatch_log_group_name
}