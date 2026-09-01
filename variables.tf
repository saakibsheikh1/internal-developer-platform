variable "aws_region" {
  description = "AWS region for the IDP infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "service_name" {
  description = "Name of the service"
  type        = string
  default     = "payment-api"
}

variable "team_name" {
  description = "Owning team"
  type        = string
  default     = "payments"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "docker_image" {
  description = "Docker image URI"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8080
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
  description = "Number of Fargate tasks"
  type        = number
  default     = 2
}

# ============================================================
# Background Worker
# ============================================================

variable "worker_queue_name" {
  description = "SQS queue name for the background worker"
  type        = string
  default     = "order-processor-dev-jobs"
}

variable "worker_docker_image" {
  description = "Docker image for the background worker"
  type        = string
}