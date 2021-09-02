#! /bin/bash
sudo yum update -y && sudo yum upgrade -y
sudo yum install epel-release -y
sudo yum install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
