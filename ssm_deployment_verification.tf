resource "aws_ssm_parameter" "deployment_verified" {
  name  = "/hello-ecs-blue-green/verified"
  type  = "String"
  value = "false"

  description = "Controls whether blue/green deployments can proceed. Set to 'true' to allow deployments, 'false' to block them."
}
