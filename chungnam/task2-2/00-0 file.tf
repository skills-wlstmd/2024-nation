resource "random_string" "file_cicd_random" {
  length           = 3
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

resource "aws_s3_bucket" "app" {
  bucket = "wsc2024-app-${random_string.file_cicd_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "appspec" {
  bucket = aws_s3_bucket.app.id
  key    = "/appspec.yml"
  source = "./src/appspec.yml"
  etag   = filemd5("./src/appspec.yml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "buildspec" {
  bucket = aws_s3_bucket.app.id
  key    = "/buildspec.yaml"
  source = "./src/buildspec.yaml"
  etag   = filemd5("./src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.app.id
  key    = "/main.py"
  source = "./src/main.py"
  etag   = filemd5("./src/main.py")
}

resource "aws_s3_object" "task" {
  bucket = aws_s3_bucket.app.id
  key    = "/taskdef.json"
  source = "./src/taskdef.json"
  etag   = filemd5("./src/taskdef.json")
  content_type = "application/json"
}

resource "aws_s3_object" "requirements" {
  bucket = aws_s3_bucket.app.id
  key    = "/requirements.txt"
  source = "./src/requirements.txt"
  etag   = filemd5("./src/requirements.txt")
}

resource "aws_s3_object" "html" {
  bucket = aws_s3_bucket.app.id
  key    = "/templates/index.html"
  source = "./src/templates/index.html"
  etag   = filemd5("./src/templates/index.html")
}