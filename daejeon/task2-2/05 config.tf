data "aws_caller_identity" "config_current" {}

resource "random_string" "s3_random" {
  length  = 4
  upper   = false
  lower   = true
  numeric = false
  special = false
}

resource "aws_s3_bucket" "config" {
  bucket        = "aws-config-${random_string.s3_random.result}"
  force_destroy = true
}

resource "aws_config_configuration_aggregator" "account" {
  name = "example"

  account_aggregation_source {
    account_ids = ["${data.aws_caller_identity.config_current.account_id}"]
    regions     = ["ap-northeast-2"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config" {
  name               = "config-rule"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "config_role" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_config_delivery_channel" "config" {
  name           = "config-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket

  depends_on = [
    aws_iam_role_policy_attachment.config_role,
    aws_config_configuration_recorder.config
  ]
}

resource "aws_config_configuration_recorder" "config" {
  name     = "config"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = false
    include_global_resource_types = false
    resource_types                = ["AWS::EC2::SecurityGroup"]
  }

  recording_mode {
    recording_frequency = "CONTINUOUS"

    recording_mode_override {
      description         = "Only record EC2 security groups daily"
      resource_types      = ["AWS::EC2::SecurityGroup"]
      recording_frequency = "CONTINUOUS"
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.config_role
  ]
}


resource "aws_config_configuration_recorder_status" "config_status" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true

  depends_on = [
    aws_config_configuration_recorder.config,
    aws_config_delivery_channel.config
  ]
}

resource "aws_config_config_rule" "config" {
  name                = "wsi-config-port"
  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.lambda.arn
    source_detail {
      event_source    = "aws.config"
      message_type    = "ConfigurationItemChangeNotification"
    }
  }
  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
    compliance_resource_id = aws_security_group.bastion.id
  }
  depends_on = [
    aws_config_configuration_recorder.config,
    aws_config_configuration_recorder_status.config_status,
    aws_lambda_permission.config
  ]
}