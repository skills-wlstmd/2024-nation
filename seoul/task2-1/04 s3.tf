resource "random_string" "bucket_random" {
  length           = 4
  upper            = false
  lower            = true
  numeric          = false
  special          = false
}
resource "aws_s3_bucket" "source" {
  bucket   = "wsi-static-${random_string.bucket_random.result}"
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.source.id
  key    = "index.html"
  source = "./src/index.html"
  etag   = filemd5("./src/index.html")
  content_type = "text/html"
}

resource "aws_s3_object" "glass" {
  bucket = aws_s3_bucket.source.id
  key    = "images/glass.jpg"
  source = "./src/images/glass.jpg"
  etag   = filemd5("./src/images/glass.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "hamster" {
  bucket = aws_s3_bucket.source.id
  key    = "images/hamster.jpg"
  source = "./src/images/hamster.jpg"
  etag   = filemd5("./src/images/hamster.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "librany" {
  bucket = aws_s3_bucket.source.id
  key    = "images/library.jpg"
  source = "./src/images/library.jpg"
  etag   = filemd5("./src/images/library.jpg")
  content_type = "image/jpeg"
}

resource "aws_s3_object" "folder1" {
    bucket = aws_s3_bucket.source.id
    key    = "dev/"
}


resource "aws_s3_bucket_policy" "cdn-oac-bucket-policy" {
  bucket = aws_s3_bucket.source.id
  policy = data.aws_iam_policy_document.static_s3_policy.json
}

data "aws_iam_policy_document" "static_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.source.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf_dist.arn]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "source" {
  bucket   = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}