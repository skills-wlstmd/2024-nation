resource "random_string" "gwangju-cicd-file_cicd_random" {
  length           = 3
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

resource "aws_s3_bucket" "gwangju-cicd-app" {
  bucket = "app-${random_string.gwangju-cicd-file_cicd_random.result}"
  force_destroy = true
}

resource "aws_s3_bucket" "gwangju-cicd-manifest" {
  bucket = "app-manifest-${random_string.gwangju-cicd-file_cicd_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "gwangju-cicd-buildspec" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/buildspec.yaml"
  source = "./src/buildspec.yaml"
  etag   = filemd5("./src/buildspec.yaml")
  content_type = "application/vnd.yaml"
}

resource "aws_s3_object" "gwangju-cicd-Docker" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/Dockerfile"
  source = "./src/Dockerfile"
  etag   = filemd5("./src/Dockerfile")
}

resource "aws_s3_object" "gwangju-cicd-app" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/main.py"
  source = "./src/main.py"
  etag   = filemd5("./src/main.py")
}

resource "aws_s3_object" "gwangju-cicd-deployment" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/deployment.yaml"
  source = "./src/deployment.yaml"
  etag   = filemd5("./src/deployment.yaml")
}

resource "aws_s3_object" "gwangju-cicd-kustomization" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/kustomization.yaml"
  source = "./src/kustomization.yaml"
  etag   = filemd5("./src/kustomization.yaml")
}

resource "aws_s3_object" "gwangju-cicd-requirements" {
  bucket = aws_s3_bucket.gwangju-cicd-app.id
  key    = "/requirements.txt"
  source = "./src/requirements.txt"
  etag   = filemd5("./src/requirements.txt")
}

resource "aws_s3_object" "gwangju-cicd-cluster" {
  bucket = aws_s3_bucket.gwangju-cicd-manifest.id
  key    = "/cluster.yaml"
  source = "./src/manifest/cluster.yaml"
  etag   = filemd5("./src/manifest/cluster.yaml")
}