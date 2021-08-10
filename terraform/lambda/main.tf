data "template_file" "lambda_policy_tpl" {
  template = file("${path.module}/files/lambda_policy.json.tpl")
  vars = {
    snstopic = aws_sns_topic.ec2_reboots.arn
  }
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
  role       = aws_iam_role.healthcheck_lambda_role.arn
}

resource "aws_lambda_function" "healthCheckFailRebootLambda" {
  function_name    = "healthCheckFailReboot"
  handler          = "healthCheckFailReboot"
  role             = aws_iam_role.healthcheck_lambda_role.arn
  runtime          = "python3.8"
  source_code_hash = filebase64sha256("../../lambda_code/ec2_restart.zip")
  environment {

  }
}

resource "aws_sns_topic_subscription" "lambda_to_sns_subs" {
  endpoint  = aws_lambda_function.healthCheckFailRebootLambda.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.ec2_reboots.arn
}
