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
resource "aws_s3_object" "Docker" {
  bucket = aws_s3_bucket.app.id
  key    = "/Dockerfile"
  source = "./src/Dockerfile"
  etag   = filemd5("./src/Dockerfile")
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.app.id
  key    = "/src/app.py"
  source = "./src/src/app.py"
  etag   = filemd5("./src/src/app.py")
}

resource "aws_s3_object" "ApplicationStop" {
  bucket = aws_s3_bucket.app.id
  key    = "/scripts/ApplicationStop.sh"
  source = "./src/scripts/ApplicationStop.sh"
  etag   = filemd5("./src/scripts/ApplicationStop.sh")
}

resource "aws_s3_object" "BeforeInstall" {
  bucket = aws_s3_bucket.app.id
  key    = "/scripts/BeforeInstall.sh"
  source = "./src/scripts/BeforeInstall.sh"
  etag   = filemd5("./src/scripts/BeforeInstall.sh")
}

resource "aws_s3_object" "ApplicationStart" {
  bucket = aws_s3_bucket.app.id
  key    = "/scripts/ApplicationStart.sh"
  source = "./src/scripts/ApplicationStart.sh"
  etag   = filemd5("./src/scripts/ApplicationStart.sh")
}

resource "aws_s3_object" "AfterInstall" {
  bucket = aws_s3_bucket.app.id
  key    = "/scripts/AfterInstall.sh"
  source = "./src/scripts/AfterInstall.sh"
  etag   = filemd5("./src/scripts/AfterInstall.sh")
}