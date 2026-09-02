variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "team_name" {
  description = "Owning team"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ALB target group ARN suffix used by CloudWatch"
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ALB load balancer ARN suffix used by CloudWatch"
  type        = string
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization alarm threshold"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "Memory utilization alarm threshold"
  type        = number
  default     = 80
}