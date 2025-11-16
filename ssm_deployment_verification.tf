resource "aws_ssm_parameter" "deployment_verified" {
  name  = "/hello-ecs-blue-green/verified"
  type  = "String"
  value = "in_progress"

  description = "Controls whether blue/green deployments can proceed. Set to 'true' to allow deployments, 'false' to block them."
}
