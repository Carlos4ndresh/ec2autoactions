output "ec2_eip" {
  value = aws_eip.elastic_ip_healthcheck.public_ip
}

output "test_fqdn" {
  value = aws_route53_record.cname_for_testec2.fqdn
}

output "ec2_id" {
  value = aws_instance.test_ec2.id
}
