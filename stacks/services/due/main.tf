terraform {
  backend "s3" {
    bucket         = "fgms-infra"
    key            = "services-due.tfstate"
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

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "dns.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "alb.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "ecs.tfstate"
    region = "eu-west-1"
  }
}


resource "aws_iam_policy" "fgms_due_task_role_policy" {
  name        = "fgms_due_task_role_policy"
  description = "fgms due task role policy"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect : "Allow",
          Action : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : "*"
        }
      ]
    }
  )
}


resource "aws_iam_role" "fgms_due_task_role" {
  name = "fgms_due_task_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect : "Allow",
          Principal : {
            Service : "ecs-tasks.amazonaws.com"
          },
          Action : [
            "sts:AssumeRole"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.fgms_due_task_role.name
  policy_arn = aws_iam_policy.fgms_due_task_role_policy.arn
}


resource "aws_ecs_task_definition" "fgms_due_td" {
  family                   = "fgms_due_td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fgms_due_task_role.arn

  container_definitions = jsonencode(
    [
      {
        cpu : 256,
        image : "248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-due:v1",
        memory : 512,
        name : "fgms-due",
        networkMode : "awsvpc",
        portMappings : [
          {
            containerPort : 3000,
            hostPort : 3000
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "fgms_due_td_service" {
  name            = "fgms_due_td_service"
  cluster         = data.terraform_remote_state.ecs_cluster.outputs.fgms_ecs_cluster_id
  task_definition = aws_ecs_task_definition.fgms_due_td.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks_sg_due.id}"]
    subnets         = ["${data.terraform_remote_state.vpc.outputs.fgms_private_subnets_ids[0]}"]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.fgms_due_service.arn
  }
}

resource "aws_security_group" "ecs_tasks_sg_due" {
  name        = "ecs_tasks_sg_due"
  description = "allow inbound access from the ALB only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.fgms_vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "3000"
    to_port     = "3000"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_service_discovery_service" "fgms_due_service" {
  name = var.fgms_due_service_namespace

  dns_config {
    namespace_id = data.terraform_remote_state.dns.outputs.fgms_dns_discovery_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}
