resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/my-app"
  retention_in_days = 7  # Optional: Retain logs for 7 days
}

#  IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
