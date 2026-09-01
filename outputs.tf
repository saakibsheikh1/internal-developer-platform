# ============================================================
# Network Outputs
# ============================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.network.nat_gateway_id
}

output "nat_eip" {
  description = "NAT Gateway Elastic IP"
  value       = module.network.nat_eip
}

# ============================================================
# ECS Outputs
# ============================================================

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
  description = "CloudWatch log group"
  value       = module.web_service.cloudwatch_log_group_name
}