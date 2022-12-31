terraform {
  backend "s3" {
    bucket         = "fgms-infra"
    key            = "dns.tfstate"
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



data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "vpc.tfstate"
    region = "eu-west-1"
  }
}


resource "aws_service_discovery_private_dns_namespace" "fgms_dns_discovery" {
  name        = var.fgms_private_dns_namespace
  description = "fgms dns discovery"
  vpc         = data.terraform_remote_state.vpc.outputs.fgms_vpc_id
}
