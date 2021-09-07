data "template_file" "lambda_policy_tpl" {
  template = file("${path.module}/files/lambda_policy.json.tpl")
  vars = {
    snstopic = aws_sns_topic.ec2_reboots.arn
  }
}

data "aws_instance" "ec2_instance" {
  instance_id = data.terraform_remote_state.ec2_outputs.outputs.ec2_id
}

data "aws_availability_zone" "current_ec2_az" {
  name = data.aws_instance.ec2_instance.availability_zone
}

resource "aws_sns_topic" "ec2_reboots" {
  name = "ec2-reboots-topic"
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda_policy"
  policy = data.template_file.lambda_policy_tpl.rendered
}

resource "aws_iam_role" "healthcheck_lambda_role" {
  name = "healthcheck_lambda_role"
  //assume_role_policy = file("./files/lambda_policy.json")
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_policy_att" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.healthcheck_lambda_role.name
}

data "archive_file" "ec2_restart" {
  type             = "zip"
  source_file      = "${path.root}/../../lambda_code/ec2_restart.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/files/ec2_restart.py.zip"
}

resource "aws_lambda_function" "healthCheckFailRebootLambda" {
  filename         = data.archive_file.ec2_restart.output_path
  function_name    = "healthCheckFailReboot"
  handler          = "ec2_restart.lambda_handler"
  role             = aws_iam_role.healthcheck_lambda_role.arn
  runtime          = "python3.8"
  source_code_hash = data.archive_file.ec2_restart.output_base64sha256
  environment {
    variables = {
      // Honestly this should be improved, we cannot build a tailored lambda for each instance
      ALARM_NAME     = aws_cloudwatch_metric_alarm.alarm.alarm_name
      REGION         = data.aws_availability_zone.current_ec2_az.region
      INSTANCE_ID    = data.aws_instance.ec2_instance.id
      OUTPUT_SNS_ARN = aws_sns_topic.ec2_reboots.arn
    }
  }
}

resource "aws_lambda_permission" "sns_to_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healthCheckFailRebootLambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ec2_reboots.arn
}

resource "aws_cloudwatch_log_group" "lambda_restart_logs" {
  name              = "/aws/lambda/${aws_lambda_function.healthCheckFailRebootLambda.function_name}"
  retention_in_days = 7
}

resource "aws_sns_topic_subscription" "lambda_to_sns_subs" {
  endpoint  = aws_lambda_function.healthCheckFailRebootLambda.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.ec2_reboots.arn
}

resource "aws_sns_topic_subscription" "email_to_sns_sub" {
  endpoint  = "carlos.herrera@outlook.com"
  protocol  = "email"
  topic_arn = aws_sns_topic.ec2_reboots.arn

}

// We can move this to the lambda module?
resource "aws_route53_health_check" "ec2_healthcheck" {
  type              = "HTTP"
  port              = 80
  fqdn              = data.terraform_remote_state.ec2_outputs.outputs.test_fqdn
  ip_address        = data.terraform_remote_state.ec2_outputs.outputs.ec2_eip
  failure_threshold = 2
  request_interval  = 30
  regions           = ["us-east-1", "us-west-2", "us-west-1"]
  resource_path     = "/"
  tags = {
    "Name" = "EC2_Healthcheck"
  }
}

/* Cloudwatch alarm should be in us-east-1, apparently doesn't support anything else, I guess as this is tied to
the healthcheck as well, the healthcheck should be placed on us-east-1 at least
*/
resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name                = "terraform-ec2-test"
  namespace                 = "AWS/Route53"
  metric_name               = "HealthCheckStatus"
  comparison_operator       = "LessThanThreshold"
  evaluation_periods        = "2"
  period                    = "60"
  statistic                 = "Minimum"
  threshold                 = "1"
  unit                      = "None"
  alarm_description         = "This metric monitors whether the service endpoint is down or not."
  alarm_actions             = [aws_sns_topic.ec2_reboots.arn]
  treat_missing_data        = "breaching"
  dimensions = {
    HealthCheckId = aws_route53_health_check.ec2_healthcheck.id
  }
}
