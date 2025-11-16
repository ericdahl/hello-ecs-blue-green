resource "aws_iam_role" "lambda_deployment_verification" {
  name               = "${local.name}-lambda-deployment-verification"
  assume_role_policy = data.aws_iam_policy_document.lambda_deployment_verification_assume.json
}

data "aws_iam_policy_document" "lambda_deployment_verification_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "lambda_deployment_verification" {
  name   = "lambda-deployment-verification"
  role   = aws_iam_role.lambda_deployment_verification.id
  policy = data.aws_iam_policy_document.lambda_deployment_verification.json
}

data "aws_iam_policy_document" "lambda_deployment_verification" {
  statement {
    sid = "SSMReadParameter"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = [
      aws_ssm_parameter.deployment_verified.arn
    ]
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.lambda_deployment_verification.arn}:*"
    ]
  }
}
