provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      "Name"       = local.name
      "Repository" = "https://github.com/ericdahl/hello-ecs-blue-green"
    }
  }
}

locals {
  name = "hello-ecs-blue-green"
}


data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}


resource "aws_ecs_cluster" "default" {
  name = local.name
}

resource "aws_ecs_capacity_provider" "example" {
  name    = local.name
  cluster = aws_ecs_cluster.default.name

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.ecs_infrastructure.arn

    instance_launch_template {
      ec2_instance_profile_arn = aws_iam_instance_profile.ecs_instance.arn
      monitoring               = "DETAILED"

      network_configuration {
        subnets         = [aws_subnet.public_1.id, aws_subnet.public_2.id]
        security_groups = [aws_security_group.ecs_host.id]
      }

      storage_configuration {
        storage_size_gib = 30
      }

      instance_requirements {
        memory_mib {
          min = 1024
          max = 8192
        }

        vcpu_count {
          min = 1
          max = 4
        }

        instance_generations = ["current"]
        cpu_manufacturers    = ["intel", "amd", "amazon-web-services"]
      }
    }
  }
}