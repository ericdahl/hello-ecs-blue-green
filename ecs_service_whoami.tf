resource "aws_ecs_task_definition" "whoami" {
  family = "${local.name}-whoami"

  container_definitions = jsonencode([
    {
      name              = "whoami"
      image             = "traefik/whoami:v1.11.0-arm64"
      essential         = true
      memory            = 512
      memoryReservation = 256

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WHOAMI_NAME"
          value = "Standard Deployment"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.whoami.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "whoami"
        }
      }
    }
  ])

  requires_compatibilities = ["MANAGED_INSTANCES"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_task_definition" "whoami_new" {
  family = "${local.name}-whoami-new"

  container_definitions = jsonencode([
    {
      name              = "whoami"
      image             = "traefik/whoami:v1.11.0-arm64"
      essential         = true
      memory            = 512
      memoryReservation = 256

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "WHOAMI_NAME"
          value = "New Deployment"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.whoami.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "whoami"
        }
      }
    }
  ])

  requires_compatibilities = ["MANAGED_INSTANCES"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }
}

resource "aws_cloudwatch_log_group" "whoami" {
  name              = "/ecs/${local.name}/whoami"
  retention_in_days = 7
}

resource "aws_lb" "whoami" {
  name               = "${local.name}-whoami"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

resource "aws_security_group" "alb" {
  name   = "${local.name}-alb"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb_target_group" "whoami_blue" {
  name        = "ecs-whoami-blue"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"

  health_check {
    path              = "/"
    healthy_threshold = 2
    interval          = 5
    timeout           = 3
  }
}

resource "aws_lb_listener" "whoami" {
  load_balancer_arn = aws_lb.whoami.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No routes matched"
      status_code  = "404"
    }
  }
}

# Production traffic rule (default)
resource "aws_lb_listener_rule" "whoami_production" {
  listener_arn = aws_lb_listener.whoami.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.whoami_blue.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# route to the green target group if there is a header "X-Blue-Green" set to "Test"
resource "aws_lb_listener_rule" "whoami_test" {
  listener_arn = aws_lb_listener.whoami.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.whoami_green.arn
  }
  condition {
    http_header {
      http_header_name = "X-Blue-Green"
      values           = ["Test"]
    }
  }
}

resource "aws_ecs_service" "whoami" {
  name            = "whoami"
  cluster         = aws_ecs_cluster.default.id
  task_definition = aws_ecs_task_definition.whoami.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    weight            = 1
    base              = 0
  }

  network_configuration {
    subnets         = [aws_subnet.public_1.id]
    security_groups = [aws_security_group.ecs_service_whoami.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.whoami_blue.arn
    container_name   = "whoami"
    container_port   = 80

    advanced_configuration {
      role_arn                   = aws_iam_role.ecs_alb_blue_green.arn
      production_listener_rule   = aws_lb_listener_rule.whoami_production.arn
      test_listener_rule         = aws_lb_listener_rule.whoami_test.arn
      alternate_target_group_arn = aws_lb_target_group.whoami_green.arn
    }
  }

  lifecycle {
    # avoiding TF chaing this all the time. Seems buggy
    ignore_changes = [load_balancer]
  }
}

output "alb_dns_name" {
  value = aws_lb.whoami.dns_name
}


resource "aws_lb_target_group" "whoami_green" {
  name        = "ecs-whoami-green"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"

  health_check {
    path              = "/"
    healthy_threshold = 2
    interval          = 5
    timeout           = 3
  }

  deregistration_delay = 0
}