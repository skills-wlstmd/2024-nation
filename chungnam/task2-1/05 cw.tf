resource "aws_cloudwatch_log_group" "trail" {
  name = "wsc2024-gvn-LG"

  tags = {
    Name = "wsc2024-gvn-LG"
  }
}

resource "aws_cloudwatch_log_subscription_filter" "filter" {
  name            = "gvn-filter"
  log_group_name  = aws_cloudwatch_log_group.trail.name
  filter_pattern  = "{ $.eventName = \"AttachRolePolicy\" }"
  destination_arn = aws_lambda_function.lambda.arn
}

resource "aws_cloudwatch_log_metric_filter" "trail-metrics" {
  log_group_name = aws_cloudwatch_log_group.lambda_log_group.name
  name = "gvn-mt-fileter"
  pattern = "%good%"
  metric_transformation {
    name      = "gvn"
    namespace = "gvn"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "metric-alarms" {
  alarm_name        = "wsc2024-gvn-alarm"
  metric_name       = aws_cloudwatch_log_metric_filter.trail-metrics.metric_transformation[0].name
  namespace         = aws_cloudwatch_log_metric_filter.trail-metrics.metric_transformation[0].namespace
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  period              = "30"
  statistic           = "Minimum"
  threshold           = "0.9"
}