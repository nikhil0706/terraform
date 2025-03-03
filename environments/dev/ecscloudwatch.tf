resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-app"
  retention_in_days = 7  # Optional: Retain logs for 7 days
}

# IAM Policy to Allow Logging (Optional if using Execution Role Policy)

resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name = "CloudWatchLogsPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          aws_cloudwatch_log_group.ecs_log_group.arn,
          "${aws_cloudwatch_log_group.ecs_log_group.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logging_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}


resource "aws_ses_email_identity" "verified_email" {
  email = "nikhil.devraj77@gmail.com"
}

resource "aws_sns_topic" "log_alert_topic" {
  name = "log-alert-topic"
}

#resource "aws_sns_topic_subscription" "email_subscription" {
#  topic_arn = aws_sns_topic.log_alert_topic.arn
#  protocol  = "email"
#  endpoint  = "nikhil.devraj77@gmail.com"  # Email to receive alerts
#}

resource "aws_cloudwatch_log_metric_filter" "error_filter" {
  name           = "error-filter"
  log_group_name = "/ecs/my-app"  # Replace with your log group
  pattern        = "\"200\""  # Log pattern to search for

  metric_transformation {
    name      = "ErrorCount"
    namespace = "LogMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_error_alarm" {
  alarm_name          = "log-error-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.error_filter.metric_transformation[0].name
  namespace           = "LogMetrics"
  period              = 30  # 30sec
  statistic           = "Sum"
  threshold           = 2  # Trigger if log appears 2+ times

  alarm_actions = [aws_sns_topic.log_alert_topic.arn]
}

resource "aws_iam_role" "ses_role" {
  name = "ses-email-sender-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "sns.amazonaws.com"
        }
      }
    ]
  })
}


resource "aws_iam_role_policy" "ses_send_policy" {
  name = "ses-send-email-policy"
  role = aws_iam_role.ses_role.id  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

