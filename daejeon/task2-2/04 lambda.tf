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
    filename = "lambda_function_payload.zip"
    function_name = "wsi-config-function"
    role = aws_iam_role.lambda.arn
    handler = "lambda_function.lambda_handler"
    timeout = "60"
    source_code_hash = data.archive_file.lambda.output_base64sha256
    runtime = "python3.12"
}

resource "aws_lambda_permission" "config" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "config.amazonaws.com"
}