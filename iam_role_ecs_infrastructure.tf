data "aws_iam_policy_document" "ecs_infrastructure_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_infrastructure" {
  name               = "${local.name}-ecs-infra"
  assume_role_policy = data.aws_iam_policy_document.ecs_infrastructure_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_infrastructure" {
  role       = aws_iam_role.ecs_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForManagedInstances"
}

data "aws_iam_policy_document" "ecs_infrastructure_pass_role" {
  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ecs_instance.arn]
  }
}

resource "aws_iam_role_policy" "ecs_infrastructure_pass_role" {
  name   = "pass-role"
  role   = aws_iam_role.ecs_infrastructure.id
  policy = data.aws_iam_policy_document.ecs_infrastructure_pass_role.json
}
