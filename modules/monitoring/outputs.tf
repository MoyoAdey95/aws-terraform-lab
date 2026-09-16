output "alarm_name" {
  description = "Name of the no healthy targets alarm."
  value       = aws_cloudwatch_metric_alarm.no_healthy_targets.alarm_name
}

output "sns_topic_arn" {
  description = "ARN of the alerts topic."
  value       = aws_sns_topic.alerts.arn
}
