terraform {
  backend "s3" {
    bucket         = "fgms-infra"
    key            = "ecs.tfstate"
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
  profile = "<YOUR AWS PROFILE NAME>"
}


resource "aws_ecs_cluster" "fgms_ecs_cluster" {
  name = "fgms_ecs_cluster"
}
