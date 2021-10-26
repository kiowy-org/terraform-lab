terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.63.0"
    }
  }

  required_version = "1.0.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}

resource "aws_s3_bucket" "monbucket" {
  bucket = "test.tf.formation.kiowy.com"
  acl    = "public-read"

  tags = {
    Name  = "Mon Bucket"
    Owner = "Benjamin"
  }

}