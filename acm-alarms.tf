data "aws_sns_topic" "techops_alert_channel" {
  name = "techops-alerts"
}

data "aws_sns_topic" "techops_notification_channel" {
  name = "techops-notifications"
}

resource "aws_cloudwatch_metric_alarm" "acm_days_to_expiry" {
  count               = var.certificate == "" ? 1 : 0
  alarm_name          = "${local.name}_cert_days_to_expiry"
  namespace           = "AWS/CertificateManager"
  metric_name         = "DaysToExpiry"
  statistic           = "Minimum"
  comparison_operator = "LessThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  actions_enabled     = true
  period              = 86400
  evaluation_periods  = 1
  threshold           = 45
  datapoints_to_alarm = 1
  dimensions = {
    CertificateArn = element(concat(aws_acm_certificate.cert.*.arn, [""]), 0)
  }
  alarm_actions = [data.aws_sns_topic.techops_alert_channel.arn]
  ok_actions    = [data.aws_sns_topic.techops_notification_channel.arn]
  tags = {
    app     = local.name
    repo    = var.github_repository
    project = var.project_name
    owner   = var.project_owner
    email   = var.project_email
  }
}
