data "aws_caller_identity" "sqs_caller" {
}

resource "aws_sqs_queue" "sqs" {
  name                      = "j-company-sqs"
  visibility_timeout_seconds =  30
  message_retention_seconds = 345600
  max_message_size          = 262144
  delay_seconds             = 0
  receive_wait_time_seconds = 0
  sqs_managed_sse_enabled = false

  tags = {
    Name = "j-company-sqs"
  }
}

data "aws_iam_policy_document" "sqs" {
  statement {
    sid    = "example-statement-s3"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:ap-northeast-2:${data.aws_caller_identity.sqs_caller.account_id}:j-company-sqs"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.sqs_caller.account_id}"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["${aws_s3_bucket.s3_backup.arn}"]
    }
  }

  statement {
    sid    = "example-statement-ec2"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["${aws_iam_role.bastion.arn}"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:ap-northeast-2:${data.aws_caller_identity.sqs_caller.account_id}:j-company-sqs"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.sqs_caller.account_id}"]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["*"]
    }
  }
}

resource "aws_sqs_queue_policy" "sqs" {
  queue_url = aws_sqs_queue.sqs.id
  policy    = data.aws_iam_policy_document.sqs.json
}