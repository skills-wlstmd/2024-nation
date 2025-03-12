resource "random_string" "file_random" {
  length  = 3
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "app" {
  bucket        = "app-${random_string.file_random.result}"
  force_destroy = true
}

resource "aws_s3_object" "eks_cluster_yaml" {
  bucket = aws_s3_bucket.app.id
  key    = "/eks/cluster.yaml"
  source = "./manifest/eks/cluster.yaml"
  etag   = filemd5("./manifest/eks/cluster.yaml")
}

resource "aws_s3_object" "employee_dockerfile" {
  bucket = aws_s3_bucket.app.id
  key    = "/image/employee/Dockerfile"
  source = "./manifest/image/employee/Dockerfile"
  etag   = filemd5("./manifest/image/employee/Dockerfile")
}

resource "aws_s3_object" "employee_app_binary" {
  bucket = aws_s3_bucket.app.id
  key    = "/image/employee/employee"
  source = "./manifest/image/employee/employee"
  etag   = filemd5("./manifest/image/employee/employee")
}

resource "aws_s3_object" "token_dockerfile" {
  bucket = aws_s3_bucket.app.id
  key    = "/image/token/Dockerfile"
  source = "./manifest/image/token/Dockerfile"
  etag   = filemd5("./manifest/image/token/Dockerfile")
}

resource "aws_s3_object" "token_binary" {
  bucket = aws_s3_bucket.app.id
  key    = "/image/token/token"
  source = "./manifest/image/token/token"
  etag   = filemd5("./manifest/image/token/token")
}

resource "aws_s3_object" "employee_deployment_yaml" {
  bucket = aws_s3_bucket.app.id
  key    = "/yaml/employee/deployment.yaml"
  source = "./manifest/yaml/employee/deployment.yaml"
  etag   = filemd5("./manifest/yaml/employee/deployment.yaml")
}

resource "aws_s3_object" "employee_service_yaml" {
  bucket = aws_s3_bucket.app.id
  key    = "/yaml/employee/service.yaml"
  source = "./manifest/yaml/employee/service.yaml"
  etag   = filemd5("./manifest/yaml/employee/service.yaml")
}

resource "aws_s3_object" "token_deployment_yaml" {
  bucket = aws_s3_bucket.app.id
  key    = "/yaml/token/deployment.yaml"
  source = "./manifest/yaml/token/deployment.yaml"
  etag   = filemd5("./manifest/yaml/token/deployment.yaml")
}

resource "aws_s3_object" "token_service_yaml" {
  bucket = aws_s3_bucket.app.id
  key    = "/yaml/token/service.yaml"
  source = "./manifest/yaml/token/service.yaml"
  etag   = filemd5("./manifest/yaml/token/service.yaml")
}
