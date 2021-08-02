terraform {
  backend "s3" {
    bucket  = "terraform-projects-state"
    key     = "ec2_autoactions.tfstate"
    region  = "us-east-2"
    dynamodb_table = "terraform-state-lock-table"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.50"
    }
  }
}
