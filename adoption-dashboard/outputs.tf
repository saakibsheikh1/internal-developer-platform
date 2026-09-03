output "metrics_lambda_name" {
  description = "Name of the platform metrics Lambda"
  value       = aws_lambda_function.platform_metrics.function_name
}

output "metrics_lambda_arn" {
  description = "ARN of the platform metrics Lambda"
  value       = aws_lambda_function.platform_metrics.arn
}

output "metrics_namespace" {
  description = "CloudWatch namespace used by platform metrics"
  value       = var.metrics_namespace
}

output "daily_schedule_name" {
  description = "EventBridge rule running the daily metrics calculation"
  value       = aws_cloudwatch_event_rule.daily_metrics.name
}

output "dashboard_name" {
  description = "CloudWatch platform health dashboard"
  value       = aws_cloudwatch_dashboard.platform_health.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the platform health dashboard"
  value       = aws_cloudwatch_dashboard.platform_health.dashboard_arn
}

output "platform_alert_topic_arn" {
  description = "SNS topic receiving platform health alerts"
  value       = aws_sns_topic.platform_alerts.arn
}

output "onboarding_failure_alarm" {
  description = "Alarm for failed onboarding pipelines"
  value       = aws_cloudwatch_metric_alarm.onboarding_failure.alarm_name
}

output "unregistered_service_alarm" {
  description = "Alarm for unregistered ECS services"
  value       = aws_cloudwatch_metric_alarm.unregistered_service.alarm_name
}

output "golden_path_compliance_alarm" {
  description = "Alarm for golden path compliance below 90 percent"
  value       = aws_cloudwatch_metric_alarm.golden_path_compliance.alarm_name
}