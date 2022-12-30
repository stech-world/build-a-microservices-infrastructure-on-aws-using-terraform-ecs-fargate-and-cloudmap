terraform {
  backend "s3" {
    bucket         = "fgms-infra"
    key            = "ecr.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform_lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.73.0"
    }
  }
}


provider "aws" {
  region  = "eu-west-1"
  profile = "default"
}



resource "aws_ecr_repository" "fgms-uno" {
  name         = "fgms-uno"
}

resource "aws_ecr_repository" "fgms-due" {
  name         = "fgms-due"
}

resource "aws_ecr_repository" "fgms-tre" {
  name         = "fgms-tre"
}
