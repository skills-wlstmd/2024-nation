resource "random_string" "bucket_original_random" {
  length           = 7
  upper            = false
  lower            = true
  numeric          = false
  special          = false
}

resource "aws_s3_bucket" "s3_original" {
  bucket   = "j-s3-bucket-${random_string.bucket_original_random.result}-original"

  tags = {
    Name = "j-s3-bucket-${random_string.bucket_original_random.result}-original"
  }
}

resource "aws_s3_bucket_versioning" "s3_original" {
  bucket   = aws_s3_bucket.s3_original.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "s3_original" {
    bucket = aws_s3_bucket.s3_original.id
    key    = "2024/"
}