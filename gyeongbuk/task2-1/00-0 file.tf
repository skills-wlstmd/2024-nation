resource "random_string" "file_cicd_random" {
  length           = 3
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

resource "aws_s3_bucket" "app" {
  bucket = "app-${random_string.file_cicd_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "buildspec" {
  bucket = aws_s3_bucket.app.id
  key    = "/buildspec.yaml"
  source = "./src/buildspec.yaml"
  etag   = filemd5("./src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "Docker" {
  bucket = aws_s3_bucket.app.id
  key    = "/Dockerfile"
  source = "./src/Dockerfile"
  etag   = filemd5("./src/Dockerfile")
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.app.id
  key    = "/index.html"
  source = "./src/index.html"
  etag   = filemd5("./src/index.html")
}