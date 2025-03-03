#resource "aws_cloudwatch_log_group" "ecs_log_group" {
#  name              = "demo-app"
#  retention_in_days = 7  # Optional: Retain logs for 7 days
#}

#resource "aws_iam_policy" "ecs_cloudwatch_policy" {
#  name = "ecs-cloudwatch-logs-policy"

#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect   = "Allow"
#        Action   = [
#          "logs:CreateLogStream",
#          "logs:PutLogEvents"
#        ]
#        Resource = "${aws_cloudwatch_log_group.ecs_log_group.arn}:*"
#      }
#    ]
#  })
#}

#resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.name
#  policy_arn = aws_iam_policy.ecs_cloudwatch_policy.arn
#}

#resource "aws_iam_role_policy_attachment" "ecs_logs_policy_attach" {
#  role       = aws_iam_role.ecs_task_execution_role.name
#  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
#}
