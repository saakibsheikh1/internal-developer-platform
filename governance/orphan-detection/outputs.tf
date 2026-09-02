output "catalogue_bucket" {
  value = aws_s3_bucket.catalogue.bucket
}

output "catalogue_object" {
  value = aws_s3_object.catalogue.key
}

output "sns_topic_arn" {
  value = aws_sns_topic.orphan_alerts.arn
}

output "lambda_name" {
  value = aws_lambda_function.orphan_detection.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.orphan_detection.arn
}

output "audit_rule" {
  value = aws_cloudwatch_event_rule.daily_audit.name
}

output "log_group" {
  value = aws_cloudwatch_log_group.lambda.name
}
