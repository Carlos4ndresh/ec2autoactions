terraform {
  backend "s3" {
    bucket         = "terraform-projects-state"
    key            = "ec2_autoactions.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock-table"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.50"
    }
  }
}

data "terraform_remote_state" "lambda_state" {
  backend = "s3"
  config = {
    bucket         = "terraform-projects-state"
    key            = "lambda_autoactions.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-state-lock-table"

  }
}
