data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions   = [
      "s3:*",
      "logs:*",
      "iam:*",
      "lambda:*",
      "cloudfront:*",
      "ec2:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "Lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_lambda_function" "lambda" {
    provider = aws.usa
    filename = "./src/lambda_function_payload.zip"
    function_name = "wsi-resizing-function"
    role = aws_iam_role.lambda.arn
    handler = "index.handler"
    timeout = "30"
    source_code_hash = filebase64sha256("./src/lambda_function_payload.zip") 
    runtime = "nodejs20.x"
    publish  = true
}