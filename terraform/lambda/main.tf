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
  role       = aws_iam_role.healthcheck_lambda_role.name
}

data "archive_file" "ec2_restart" {
  type = "zip"
  source_file = "${path.root}/../../lambda_code/ec2_restart.py"
  output_file_mode = "0666"
  output_path = "${path.module}/files/ec2_restart.py.zip"
}

resource "aws_lambda_function" "healthCheckFailRebootLambda" {
  filename         = "${path.module}/files/ec2_restart.py.zip"
  function_name    = "healthCheckFailReboot"
  handler          = "healthCheckFailReboot.lambda_handler"
  role             = aws_iam_role.healthcheck_lambda_role.arn
  runtime          = "python3.8"
  source_code_hash = data.archive_file.ec2_restart.output_base64sha256
  environment {
    variables = {
      ALARM_NAME     = "INSERT_ALARM_NAME"
      REGION         = "us-east-1"
      INSTANCE_ID    = "i-xxxxxxx"
      OUTPUT_SNS_ARN = aws_sns_topic.ec2_reboots.arn
    }
  }
}

resource "aws_sns_topic_subscription" "lambda_to_sns_subs" {
  endpoint  = aws_lambda_function.healthCheckFailRebootLambda.arn
  protocol  = "lambda"
  topic_arn = aws_sns_topic.ec2_reboots.arn
}

resource "aws_sns_topic_subscription" "email_to_sns_sub" {
  endpoint = "carlos.herrera@outlook.com"
  protocol = "email"
  topic_arn = aws_sns_topic.ec2_reboots.arn

}
