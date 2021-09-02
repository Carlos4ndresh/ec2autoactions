output "sns_topic_arn" {
  value = aws_sns_topic.ec2_reboots.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.healthcheck_lambda_role.arn
}
