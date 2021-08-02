terraform {
  backend "s3" {
    bucket  = "terraform-projects-state"
    key     = "lambda_autoactions.tfstate"
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

provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "cherrera"
    }
  }
}
