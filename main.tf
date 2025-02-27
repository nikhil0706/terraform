provider "aws" {
  version = "~> 2.0"
  region  = "us-east-2"
}

#terraform {
#  backend "s3" {
#    bucket = "terraform-ecs-presnetation"
#    key    = "Aws-default-infrastructure"
#    region = "us-east-2"
#  }
#}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-ecs-presnetation"

  versioning {
    enabled = true
  }
}

