resource "aws_security_group" "ecs_host" {
  name   = "${local.name}-ecs-host"
  vpc_id = aws_vpc.default.id
}

resource "aws_vpc_security_group_egress_rule" "ecs_host_all" {
  security_group_id = aws_security_group.ecs_host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
