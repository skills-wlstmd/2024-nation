resource "random_string" "s3_random" {
  length           = 4
  upper            = false
  lower            = true
  numeric          = false
  special          = false
}

resource "aws_s3_bucket" "s3" {
  bucket   = "wsc-frontend-${random_string.s3_random.result}"
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.s3.id
  key    = "static/index.html"
  source = "./src/static/index.html"
  etag   = filemd5("./src/static/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "customer" {
  bucket = aws_s3_bucket.s3.id
  key    = "customer"
  source = "./src/app/customer"
  etag   = filemd5("./src/app/customer")
  content_type = "application/octet-stream"
}

resource "aws_s3_object" "product" {
  bucket = aws_s3_bucket.s3.id
  key    = "product"
  source = "./src/app/product"
  etag   = filemd5("./src/app/product")
  content_type = "application/octet-stream"
}

resource "aws_s3_object" "order" {
  bucket = aws_s3_bucket.s3.id
  key    = "order"
  source = "./src/app/order"
  etag   = filemd5("./src/app/order")
  content_type = "application/octet-stream"
}

resource "aws_s3_bucket_website_configuration" "s3" {
  bucket = aws_s3_bucket.s3.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "s3" {
  bucket   = aws_s3_bucket.s3.id
  versioning_configuration {
    status = "Enabled"
  }
}