resource "aws_iam_role" "ecs_invoke_lambda" {
  name               = "${local.name}-ecs-call-lambda"
  assume_role_policy = data.aws_iam_policy_document.ecs_invoke_lambda_assume.json
}

data "aws_iam_policy_document" "ecs_invoke_lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_invoke_lambda" {
  name   = "ecs-invoke-lambda"
  role   = aws_iam_role.ecs_invoke_lambda.id
  policy = data.aws_iam_policy_document.ecs_invoke_lambda.json
}

data "aws_iam_policy_document" "ecs_invoke_lambda" {
  statement {
    sid = "InvokeLambda"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.deployment_verification.arn
    ]
  }
}
