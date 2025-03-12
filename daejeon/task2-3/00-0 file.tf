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

resource "aws_s3_object" "Dockefile" {
  bucket = aws_s3_bucket.app.id
  key    = "/Dockerfile"
  source = "./src/Dockerfile"
  etag   = filemd5("./src/Dockerfile")
}

resource "aws_s3_object" "python" {
  bucket = aws_s3_bucket.app.id
  key    = "/app.py"
  source = "./src/app.py"
  etag   = filemd5("./src/app.py")
}

resource "aws_s3_object" "cluster" {
  bucket = aws_s3_bucket.manifest.id
  key    = "/cluster.yaml"
  source = "./manifest/cluster.yaml"
  etag   = filemd5("./manifest/cluster.yaml")
}