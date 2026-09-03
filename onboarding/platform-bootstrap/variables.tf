variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Platform environment"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Platform VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}
