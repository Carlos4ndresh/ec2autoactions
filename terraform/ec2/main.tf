provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "cherrera"
    }
  }
}

// Implement Sec group SSH only for my IP
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

resource "aws_security_group" "allow_ssh_from_my_ip" {
  name        = "allow_ssh_only_from_my_ip"
  description = "the name says it all"
  vpc_id      = data.aws_vpc.region_vpc.id
  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    description = "SSH from My IP"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// include security group for only my public IP
resource "aws_instance" "test_ec2" {
  ami             = data.aws_ami.latest_centos.id
  instance_type   = "t3.micro"
  key_name        = "nvirginia_ec2_key"
  vpc_security_group_ids = [aws_security_group.allow_ssh_from_my_ip.id]

  root_block_device {
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
