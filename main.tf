provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2"
}

#terraform {
#  backend "s3" {
#    bucket = "terraform-ECS-presnetation"
#    key    = "Aws-default-infrastructure"
#    region = "us-east-2"
#  }
#}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-ECS-presnetation"

  versioning {
    enabled = true
  }
}

