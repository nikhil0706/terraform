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


resource "aws_cloudwatch_log_metric_filter" "log_pattern_filter" {
  name           = "error-log-filter"
  log_group_name = aws_cloudwatch_log_group.ecs_log_group.name

  # Define the pattern to match logs (replace "ERROR" with your pattern)
  pattern = "{ $.message = \"*200*\" }"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "ECSLogs"
    value     = "1"
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_error_alarm" {
  alarm_name          = "ECS-Error-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10
  metric_name         = aws_cloudwatch_log_metric_filter.log_pattern_filter.metric_transformation[0].name
  namespace           = "ECSLogs"
  period              = 60  # 60 seconds (1 minute)
  statistic           = "Sum"

  alarm_description = "Triggers if logs exceed 10 times in a minute."
}


resource "aws_sns_topic" "ecs_alarm_topic" {
  name = "ecs-alarm-topic"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.ecs_alarm_topic.arn
  protocol  = "email"
  endpoint  = "nikhil.devraj77@gmail.com"  # Replace with your email
}

resource "aws_cloudwatch_metric_alarm" "ecs_error_alarm" {
  alarm_name          = "ECS-Error-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10
  metric_name         = aws_cloudwatch_log_metric_filter.log_pattern_filter.metric_transformation[0].name
  namespace           = "ECSLogs"
  period              = 60
  statistic           = "Sum"

  alarm_description = "Triggers if error logs exceed 10 times in a minute."
  alarm_actions     = [aws_sns_topic.ecs_alarm_topic.arn]  # Send alarm notifications to SNS
}


