variable "service_name" {
  description = "Name of the web service"
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
  description = "Docker image for the web service"
  type        = string
}

variable "alert_email" {
  description = "Email address for service alerts"
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
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

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
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
  description = "Number of desired ECS tasks"
  type        = number
  default     = 2
}

variable "cosign_public_key_path" {
  description = "Path to the Cosign public key used to verify the container image"
  type        = string
  default     = "../../cosign.pub"
}

variable "route53_zone_id" {
  description = "Optional Route53 hosted zone ID for the service DNS record"
  type        = string
  default     = null
}

variable "route53_record_name" {
  description = "Optional Route53 DNS record name"
  type        = string
  default     = null
}