variable "service_name" {
  description = "Name of the worker service"
  type        = string
}

variable "team_name" {
  description = "Owning team"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "docker_image" {
  description = "Docker image for the worker"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "cpu" {
  description = "CPU units for the Fargate task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MiB for the Fargate task"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of worker tasks"
  type        = number
  default     = 1
}

variable "min_capacity" {
  description = "Minimum number of worker tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of worker tasks"
  type        = number
  default     = 5
}

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "SQS message visibility timeout"
  type        = number
  default     = 60
}

variable "max_receive_count" {
  description = "Maximum receives before moving a message to the DLQ"
  type        = number
  default     = 3
}