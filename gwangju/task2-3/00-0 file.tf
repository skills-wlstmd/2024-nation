resource "random_string" "file_observability_random" {
  length           = 3
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

resource "aws_s3_bucket" "app" {
  bucket = "app-${random_string.file_observability_random.result}"
  force_destroy = true
}

resource "aws_s3_bucket" "manifest" {
  bucket = "app-manifest-${random_string.file_observability_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "service-a-Dockefile" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-a/Dockerfile"
  source = "./src/service-a/Dockerfile"
  etag   = filemd5("./src/service-a/Dockerfile")
}

resource "aws_s3_object" "service-a-python" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-a/app.py"
  source = "./src/service-a/app.py"
  etag   = filemd5("./src/service-a/app.py")
}

resource "aws_s3_object" "service-a-requirements" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-a/requirements.txt"
  source = "./src/service-a/requirements.txt"
  etag   = filemd5("./src/service-a/requirements.txt")
}

resource "aws_s3_object" "service-b-Dockefile" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-b/Dockerfile"
  source = "./src/service-b/Dockerfile"
  etag   = filemd5("./src/service-b/Dockerfile")
}

resource "aws_s3_object" "service-b-python" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-b/app.py"
  source = "./src/service-b/app.py"
  etag   = filemd5("./src/service-b/app.py")
}

resource "aws_s3_object" "service-c-Dockefile" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-c/Dockerfile"
  source = "./src/service-c/Dockerfile"
  etag   = filemd5("./src/service-c/Dockerfile")
}

resource "aws_s3_object" "service-c-python" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-c/app.py"
  source = "./src/service-c/app.py"
  etag   = filemd5("./src/service-c/app.py")
}

resource "aws_s3_object" "service-c-requirements" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-c/requirements.txt"
  source = "./src/service-c/requirements.txt"
  etag   = filemd5("./src/service-c/requirements.txt")
}

resource "aws_s3_object" "service-b-requirements" {
  bucket = aws_s3_bucket.app.id
  key    = "/service-b/requirements.txt"
  source = "./src/service-b/requirements.txt"
  etag   = filemd5("./src/service-b/requirements.txt")
}

resource "aws_s3_object" "cluster" {
  bucket = aws_s3_bucket.manifest.id
  key    = "/cluster.yaml"
  source = "./manifest/cluster.yaml"
  etag   = filemd5("./manifest/cluster.yaml")
}