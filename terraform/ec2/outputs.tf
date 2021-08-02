output "ec2_eip" {
  value = aws_eip.elastic_ip_healthcheck.public_ip
}

output "test_fqdn" {
  value = aws_route53_record.cname_for_testec2.fqdn
}
