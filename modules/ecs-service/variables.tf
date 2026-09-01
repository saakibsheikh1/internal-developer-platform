variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "team_name" {
  description = "Owning team for the service"
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
  description = "Docker image URI to deploy"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
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

  validation {
    condition     = var.desired_count >= 2
    error_message = "The web service must run at least 2 Fargate tasks."
  }
}

variable "vpc_id" {
  description = "VPC ID where the ECS service will run"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnets are required."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "At least two public subnets are required for the ALB."
  }
}

variable "aws_region" {
  description = "AWS region where the ECS service is deployed"
  type        = string
}