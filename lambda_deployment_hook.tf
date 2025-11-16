resource "aws_lambda_function" "deployment_verification" {
  filename      = "lambda_deployment_verification.zip"
  function_name = "${local.name}-deployment-verification"
  role          = aws_iam_role.lambda_deployment_verification.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 30

  source_code_hash = data.archive_file.lambda_deployment_verification.output_base64sha256

  environment {
    variables = {
      SSM_PARAMETER_NAME = aws_ssm_parameter.deployment_verified.name
    }
  }
}

data "archive_file" "lambda_deployment_verification" {
  type        = "zip"
  output_path = "${path.module}/lambda_deployment_verification.zip"

  source {
    content  = file("${path.module}/lambda_deployment_verification.py")
    filename = "index.py"
  }
}

resource "aws_lambda_permission" "allow_ecs" {
  statement_id  = "AllowExecutionFromECS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.deployment_verification.function_name
  principal     = "ecs.amazonaws.com"
}

resource "aws_cloudwatch_log_group" "lambda_deployment_verification" {
  name              = "/aws/lambda/${aws_lambda_function.deployment_verification.function_name}"
  retention_in_days = 7
}
