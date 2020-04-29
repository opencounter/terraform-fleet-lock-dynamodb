resource aws_cloudwatch_metric_alarm _5xx_errors {
  alarm_name        = "${module.label.id}-5xx-errors"
  alarm_description = "5xx errors occurred in ${aws_api_gateway_rest_api.this.name}"

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"
  dimensions = {
    ApiName = aws_api_gateway_rest_api.this.name
    Stage   = aws_api_gateway_stage.this.stage_name
  }
  statistic           = "Sum"
  period              = "60"
  evaluation_periods  = "1"
  comparison_operator = "GreaterThanThreshold"
  threshold           = "0"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.alarm_topic_arn]
  ok_actions          = [var.alarm_topic_arn]
  tags                = module.label.tags
}

# resource aws_cloudwatch_metric_alarm _4xx_errors {
#   alarm_name        = "${module.label.id}-4xx-errors"
#   alarm_description = "4xx errors occurred in ${aws_api_gateway_rest_api.this.name}"

#   namespace   = "AWS/ApiGateway"
#   metric_name = "4XXError"
#   dimensions = {
#     ApiName = aws_api_gateway_rest_api.this.name
#     Stage   = aws_api_gateway_stage.this.stage_name
#   }
#   statistic           = "Sum"
#   period              = "60"
#   evaluation_periods  = "1"
#   comparison_operator = "GreaterThanThreshold"
#   threshold           = "0"
#   treat_missing_data  = "notBreaching"
#   alarm_actions       = [var.alarm_topic_arn]
#   ok_actions          = [var.alarm_topic_arn]
#   tags                = module.label.tags
# }

resource aws_cloudwatch_dashboard this {
  dashboard_name = module.label.id
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 9
        height = 9
        properties = {
          title   = "APIGW Requests"
          view    = "timeSeries"
          stat    = "Sum"
          period  = 900
          region  = data.aws_region.this.name
          stacked = false
          metrics = [
            [
              "AWS/ApiGateway", "Count",
              "ApiName", aws_api_gateway_rest_api.this.name,
              "Stage", aws_api_gateway_stage.this.stage_name,
              { label = "[sum: $${SUM}] Total" },
            ],
            [
              ".", "5XXError",
              ".", ".",
              ".", ".",
              { label = "[sum: $${SUM}] 5XXError" },
            ],
            [
              ".", "4XXError",
              ".", ".",
              ".", ".",
              { label = "[sum: $${SUM}] 4XXError" },
            ]
          ],
        }
      }
    ]
  })
}
