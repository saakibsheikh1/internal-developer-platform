variable "aws_region" {
  description = "AWS region for the platform metrics stack"
  type        = string
  default     = "ap-south-1"
}

variable "metrics_namespace" {
  description = "CloudWatch namespace for IDP platform metrics"
  type        = string
  default     = "IDP/Platform"
}

variable "alert_email" {
  description = "Email address for platform alerts"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "catalogue_bucket_name" {
  description = "S3 bucket containing the generated IDP catalogue data"
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "ECS cluster to inspect for registered/unregistered services"
  type        = string
  default     = ""
}

variable "schedule_expression" {
  description = "EventBridge schedule for the daily platform metrics calculation"
  type        = string
  default     = "rate(1 day)"
}