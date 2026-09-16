# Alerting when the app has no healthy target behind the load balancer. This
# is the AWS version of the uptime check and email alert in gcp-terraform-lab.

resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
}

# Email subscriptions stay "pending confirmation" until the link in the
# confirmation email is clicked. Terraform cannot click it, so nothing is
# delivered until that happens.
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# HealthyHostCount below 1, rather than UnHealthyHostCount above 0. If the
# service scales to zero or every task is stopped, there are no unhealthy
# targets either, so an UnHealthyHostCount alarm would stay quiet through a
# full outage.
#
# Tested by scaling the service to zero. The load balancer stops publishing
# HealthyHostCount once the target group is empty, so the alarm has no zero
# to compare against and relies on missing data counting as breaching. That
# worked, but slowly. The last target was deregistered at 16:23 and the alarm
# went to ALARM at 16:32, about nine minutes, where two one-minute periods
# suggest two. Anything that needs faster detection than that should not
# depend on missing data.
resource "aws_cloudwatch_metric_alarm" "no_healthy_targets" {
  alarm_name          = "${var.name_prefix}-no-healthy-targets"
  alarm_description   = "No healthy targets behind the load balancer, so the app is down."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HealthyHostCount"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "breaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
