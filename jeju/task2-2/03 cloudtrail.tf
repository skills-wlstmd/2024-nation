data "aws_caller_identity" "trail_current" {}

data "aws_partition" "trail_current" {}

data "aws_region" "trail_current" {}

resource "random_string" "trail_random" {
  length  = 5
  upper   = false
  lower   = false
  numeric = true
  special = false
}

resource "aws_s3_bucket" "trail" {
  bucket        = "cg-trail-logs-${random_string.trail_random.result}"
  force_destroy = true
}

data "aws_iam_policy_document" "trail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.trail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.trail_current.partition}:cloudtrail:${data.aws_region.trail_current.name}:${data.aws_caller_identity.trail_current.account_id}:trail/cg-trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.trail.arn}/prefix/AWSLogs/${data.aws_caller_identity.trail_current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.trail_current.partition}:cloudtrail:${data.aws_region.trail_current.name}:${data.aws_caller_identity.trail_current.account_id}:trail/cg-trail"]
    }
  }
}

resource "aws_iam_role" "cloudtrail_role" {
  name = "cg-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudtrail_role_policy" {
  role       = aws_iam_role.cloudtrail_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.trail.id
  policy = data.aws_iam_policy_document.trail.json
}

resource "aws_cloudwatch_log_group" "trail" {
  name = "cg-logs"

  tags = {
    Name = "cg-logs"
  }
}

resource "aws_cloudtrail" "trail" {
  depends_on = [aws_s3_bucket_policy.trail, aws_cloudwatch_log_group.trail]

  name                          = "cg-trail"
  s3_bucket_name                = aws_s3_bucket.trail.id
  s3_key_prefix                 = "prefix"
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.trail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_role.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  event_selector {
    read_write_type             = "All"
    include_management_events   = true
  }

  tags = {
    Name = "cg-trail"
  }
}


resource "aws_cloudwatch_log_metric_filter" "trail" {
  name           = "ssm-connection"
  pattern        = "%StartSession%"
  log_group_name = aws_cloudwatch_log_group.trail.name

  metric_transformation {
    namespace = "ssm-connection"
    name      = "ssm-connection"
    value     = "1"
  }
}

resource "aws_cloudwatch_dashboard" "tail" {
  dashboard_name = "cg-dashboard"
  dashboard_body = "${file("./src/widgets.json")}"
}

resource "aws_cloudwatch_query_definition" "trail" {
  name            = "SSMConnectionQuery"
  log_group_names = [aws_cloudwatch_log_group.trail.name]
  query_string    = "${file("./src/ssm_connection_query.txt")}"
}
