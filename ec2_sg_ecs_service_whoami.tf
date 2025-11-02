resource "aws_security_group" "ecs_service_whoami" {
  name   = "${local.name}-ecs-service-whoami"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "ecs_service_whoami_from_alb" {
  security_group_id            = aws_security_group.ecs_service_whoami.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_service_whoami_all" {
  security_group_id = aws_security_group.ecs_service_whoami.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
