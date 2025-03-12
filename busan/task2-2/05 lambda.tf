data "aws_region" "cw_current" {}

resource "aws_iam_role" "lambda" {
  name = "lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "./src/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda" {
    function_name = "wsi-project-log-function"
    handler = "lambda_function.lambda_handler"
    filename = "lambda_function_payload.zip"
    role = aws_iam_role.lambda.arn
    timeout = "60"
    source_code_hash = data.archive_file.lambda.output_base64sha256
    runtime = "python3.12"
    publish = true
}

resource "aws_lambda_permission" "logging" {
  action = "lambda:InvokeFunction"
  function_name =  aws_lambda_function.lambda.function_name
  principal = "logs.${data.aws_region.cw_current.name}.amazonaws.com"
  source_arn = "${aws_cloudwatch_log_group.trail.arn}:*"

  depends_on = [aws_lambda_function.lambda]
} 

resource "aws_cloudwatch_log_subscription_filter" "trail" {
  name            = "trail-filter"
  destination_arn = aws_lambda_function.lambda.arn
  log_group_name  = aws_cloudwatch_log_group.trail.name
  filter_pattern  = "{ $.eventName = \"ConsoleLogin\" }"

  depends_on = [aws_lambda_permission.logging]
}