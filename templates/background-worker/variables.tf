variable "service_name" {
  description = "Name of the background worker"
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

variable "docker_image" {
  description = "Docker image for the background worker"
  type        = string
}

variable "alert_email" {
  description = "Email address for worker alerts"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial desired worker count"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum autoscaling capacity"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum autoscaling capacity"
  type        = number
  default     = 5
}

variable "queue_name" {
  description = "SQS queue name"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "SQS visibility timeout"
  type        = number
  default     = 60
}

variable "max_receive_count" {
  description = "Maximum receives before sending to DLQ"
  type        = number
  default     = 3
}