variable "job_name" {
  description = "Name of the scheduled job"
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
  description = "Docker image for the scheduled job"
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge Scheduler schedule expression"
  type        = string
  default     = "rate(1 day)"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_id" {
  description = "VPC ID for the scheduled job"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the scheduled job"
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