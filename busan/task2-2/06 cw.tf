resource "aws_cloudwatch_log_group" "logging" {
  name = "wsi-project-login"

  tags = {
    Name = "wsi-project-login"
  }
}

resource "aws_cloudwatch_log_stream" "logging" {
  name = "wsi-project-login-stream"
  log_group_name = aws_cloudwatch_log_group.logging.name
}