resource "random_string" "s3_bucket_random" {
  length           = 7
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_replication" {
  name               = "tf-iam-role-replication-${random_string.s3_bucket_random.result}"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

data "aws_iam_policy_document" "s3_replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.s3_original.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.s3_original.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.s3_backup.arn}/*"]
  }
  depends_on = [aws_s3_bucket.s3_original, aws_s3_bucket.s3_backup]
}

resource "aws_iam_policy" "s3_replication" {
  name   = "tf-iam-role-policy-replication-${random_string.s3_bucket_random.result}"
  policy = data.aws_iam_policy_document.s3_replication.json
}

resource "aws_iam_role_policy_attachment" "s3_replication" {
  role       = aws_iam_role.s3_replication.name
  policy_arn = aws_iam_policy.s3_replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.s3_original, aws_s3_bucket_versioning.s3_backup]

  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.s3_original.id

  rule {
    id     = "ReplicationRule"
    status = "Enabled"

    filter {
      prefix = "2024/"
    }
    destination {
      bucket        = aws_s3_bucket.s3_backup.arn
      storage_class = "STANDARD"
    }

    delete_marker_replication {
      status = "Disabled"
    }
  }
}