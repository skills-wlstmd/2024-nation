data "aws_iam_policy_document" "gwangju-cicd-assume_role_build" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gwangju-cicd-build" {
  name               = "codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.gwangju-cicd-assume_role_build.json
}

data "aws_iam_policy_document" "gwangju-cicd-build" {
  statement {
    effect = "Allow"

    actions = [
      "logs:*",
      "s3:*",
      "ecr:*",
      "codestar-connections:*",
      "codecommit:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gwangju-cicd-build" {
  role   = aws_iam_role.gwangju-cicd-build.name
  policy = data.aws_iam_policy_document.gwangju-cicd-build.json
}

resource "aws_codebuild_project" "gwangju-cicd-build" {
  name          = "wsi-build"
  service_role  = aws_iam_role.gwangju-cicd-build.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/wsi-build"
      stream_name = "build_log"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yaml"
  }
}