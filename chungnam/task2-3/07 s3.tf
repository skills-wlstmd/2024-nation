resource "random_string" "bucket_random" {
  length           = 4
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

resource "aws_s3_bucket" "source" {
  bucket   = "gm-${random_string.bucket_random.result}"
}