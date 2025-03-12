resource "random_string" "bucket_backup_random" {
  length           = 7
  upper            = false
  lower            = true
  numeric          = false
  special          = false
}

resource "aws_s3_bucket" "s3_backup" {
  bucket   = "j-s3-bucket-${random_string.bucket_backup_random.result}-backup"

  tags = {
    Name = "j-s3-bucket-${random_string.bucket_backup_random.result}-backup"
  }
}

resource "aws_s3_bucket_notification" "s3_backup" {
  bucket = aws_s3_bucket.s3_backup.id

  queue {
    queue_arn     = aws_sqs_queue.sqs.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "2024/"
  }
  depends_on = [ aws_s3_bucket.s3_backup, aws_sqs_queue.sqs ]
}

resource "aws_s3_bucket_versioning" "s3_backup" {
  bucket   = aws_s3_bucket.s3_backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "s3_backup" {
    bucket = aws_s3_bucket.s3_backup.id
    key    = "2024/"
}