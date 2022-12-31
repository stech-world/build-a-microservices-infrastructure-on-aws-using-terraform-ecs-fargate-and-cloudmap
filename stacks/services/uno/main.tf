terraform {
  backend "s3" {
    bucket         = "fgms-infra"
    key            = "services-uno.tfstate"
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

data "terraform_remote_state" "services-tre" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "services-tre.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "services-due" {
  backend = "s3"
  config = {
    bucket = "fgms-infra"
    key    = "services-due.tfstate"
    region = "eu-west-1"
  }
}



resource "aws_iam_policy" "fgms_uno_task_role_policy" {
  name        = "fgms_uno_task_role_policy"
  description = "fgms uno task role policy"

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


resource "aws_iam_role" "fgms_uno_task_role" {
  name = "fgms_uno_task_role"

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
  role       = aws_iam_role.fgms_uno_task_role.name
  policy_arn = aws_iam_policy.fgms_uno_task_role_policy.arn
}

resource "aws_cloudwatch_log_group" "fgms_log_group" {
  name = "/ecs/fgms_log_group"

}


resource "aws_ecs_task_definition" "fgms_uno_td" {
  family                   = "fgms_uno_td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fgms_uno_task_role.arn

  container_definitions = jsonencode(
    [
      {
        cpu : 256,
        image : "248581660709.dkr.ecr.eu-west-1.amazonaws.com/fgms-uno:v1",
        memory : 512,
        name : "fgms-uno",
        networkMode : "awsvpc",
        environment : [
          {
            name : "DUE_SERVICE_API_BASE",
            value : "http://${data.terraform_remote_state.services-due.outputs.fgms_due_service_namespace}.${data.terraform_remote_state.dns.outputs.fgms_private_dns_namespace}"
          },
          {
            name : "TRE_SERVICE_API_BASE",
            value : "http://${data.terraform_remote_state.services-tre.outputs.fgms_tre_service_namespace}.${data.terraform_remote_state.dns.outputs.fgms_private_dns_namespace}"
          }
        ],
        portMappings : [
          {
            containerPort : 3000,
            hostPort : 3000
          }
        ],
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-group : "/ecs/fgms_log_group",
            awslogs-region : "eu-west-1",
            awslogs-stream-prefix : "uno"
          }
        }
      }
    ]
  )
}

resource "aws_ecs_service" "fgms_uno_td_service" {
  name            = "fgms_uno_td_service"
  cluster         = data.terraform_remote_state.ecs_cluster.outputs.fgms_ecs_cluster_id
  task_definition = aws_ecs_task_definition.fgms_uno_td.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks_sg.id}"]
    subnets         = ["${data.terraform_remote_state.vpc.outputs.fgms_private_subnets_ids[0]}"]
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.fgms_uno_tg.id
    container_name   = "fgms-uno"
    container_port   = 3000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.fgms_uno_service.arn
  }
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs_tasks_sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.fgms_vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = "3000"
    to_port         = "3000"
    security_groups = ["${data.terraform_remote_state.alb.outputs.fgms_alb_sg_id}"]
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


resource "aws_alb_target_group" "fgms_uno_tg" {
  name        = "fgms-uno-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.fgms_vpc_id
  target_type = "ip"
  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener" "fgms_uno_tg_listener" {
  load_balancer_arn = data.terraform_remote_state.alb.outputs.fgms_alb_id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.fgms_uno_tg.id
    type             = "forward"
  }
}


resource "aws_service_discovery_service" "fgms_uno_service" {
  name = var.fgms_uno_service_namespace

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
