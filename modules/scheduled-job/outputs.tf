# ------------------------------------------------------------
# ECS Outputs
# ------------------------------------------------------------

output "ecs_cluster_name" {
  description = "Scheduled job ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "task_definition_arn" {
  description = "Scheduled job ECS task definition ARN"
  value       = aws_ecs_task_definition.this.arn
}

# ------------------------------------------------------------
# EventBridge Scheduler Outputs
# ------------------------------------------------------------

output "schedule_name" {
  description = "EventBridge Scheduler schedule name"
  value       = aws_scheduler_schedule.this.name
}

# ------------------------------------------------------------
# Lambda Outputs
# ------------------------------------------------------------

output "lambda_function_name" {
  description = "Lambda function that launches the scheduled ECS task"
  value       = aws_lambda_function.launcher.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.launcher.arn
}

# ------------------------------------------------------------
# SQS DLQ Outputs
# ------------------------------------------------------------

output "dlq_name" {
  description = "SQS dead letter queue name"
  value       = aws_sqs_queue.dlq.name
}

output "dlq_url" {
  description = "SQS dead letter queue URL"
  value       = aws_sqs_queue.dlq.url
}

# ------------------------------------------------------------
# CloudWatch Outputs
# ------------------------------------------------------------

output "log_group_name" {
  description = "CloudWatch log group used for scheduled job execution history"
  value       = aws_cloudwatch_log_group.this.name
}