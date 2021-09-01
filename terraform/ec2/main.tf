provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "cherrera"
    }
  }
}

data "aws_vpc" "region_vpc" {
}

data "aws_ami" "latest_centos" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }
}

resource "aws_instance" "test_ec2" {
  ami           = data.aws_ami.latest_centos.id
  instance_type = "t3.micro"
  key_name      = "generic_ec2_key"

  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 80
    volume_type           = "gp3"
  }
  tags = {
    Name = "Test_HealthChecks_EC2"
  }
  user_data = file("${path.module}/userdata.tpl")
}

resource "aws_eip" "elastic_ip_healthcheck" {
  vpc      = true
  instance = aws_instance.test_ec2.id
}


data "aws_route53_zone" "test_zone" {
  name         = "carlos4ndresh.com."
  private_zone = false
}

resource "aws_route53_record" "cname_for_testec2" {
  name    = "test"
  type    = "CNAME"
  ttl     = 300
  zone_id = data.aws_route53_zone.test_zone.id
  records = [aws_eip.elastic_ip_healthcheck.public_ip]
}

resource "aws_route53_health_check" "ec2_healthcheck" {
  type                  = "HTTP"
  port                  = 80
  fqdn                  = aws_route53_record.cname_for_testec2.fqdn
  ip_address            = aws_eip.elastic_ip_healthcheck.public_ip
  failure_threshold     = 2
  request_interval      = 30
  cloudwatch_alarm_name = aws_cloudwatch_metric_alarm.alarm.alarm_name
  regions               = ["us-east-1", "us-east-2"]
  resource_path         = "/"
}
resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name          = "terraform-ec2-test"
  comparison_operator = ""
  evaluation_periods  = 0
}
