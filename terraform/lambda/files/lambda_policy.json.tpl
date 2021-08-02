{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SNS",
      "Action": [
        "sns:Publish"
      ],
      "Effect": "Allow",
      "Resource": "${snstopic}"
    },
    {
      "Sid": "logs",
      "Action": [
        "logs:CreateLogDelivery",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Sid": "ec2s",
      "Action": [
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeInstances",
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
