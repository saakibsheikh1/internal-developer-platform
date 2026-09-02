variable "aws_region" {
  description = "AWS region for orphan detection"
  type        = string
  default     = "ap-south-1"
}

variable "alert_email" {
  description = "Email address for orphan detection alerts"
  type        = string
}

variable "catalogue_bucket_name" {
  description = "S3 bucket containing the service catalogue snapshot"
  type        = string
}

variable "catalogue_object_key" {
  description = "S3 object key containing the service catalogue JSON"
  type        = string
  default     = "catalogue/services.json"
}

variable "audit_schedule" {
  description = "Daily EventBridge audit schedule"
  type        = string
  default     = "rate(1 day)"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "internal-developer-platform"
}
