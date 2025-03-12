variable "file_name" {
  type        = string
  default     = "imagedefinitions.json"
}

resource "aws_codepipeline" "gwangju-cicd-pipeline" {
  name     = "pipeline"
  role_arn = aws_iam_role.gwangju-cicd-codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.gwangju-cicd-pipeline.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.wlstmd.arn
        FullRepositoryId = "wlstmd/gwangju-application-repo"
        BranchName = "master"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.gwangju-cicd-build.name
      }
    }
  }
}

resource "aws_s3_bucket" "gwangju-cicd-pipeline" {
  bucket_prefix = "gwangju-artifacts"
  force_destroy = true
}

data "aws_iam_policy_document" "gwangju-cicd-assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "gwangju-cicd-codepipeline_role" {
  name               = "gwangju-role-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.gwangju-cicd-assume_role_pipeline.json
}

data "aws_iam_policy_document" "gwangju-cicd-codepipeline_policy" {
  statement {
    effect = "Allow"

    actions = [
      "kms:*",
      "codestar-connections:*",
      "codebuild:*",
      "logs:*",
      "codedeploy:*",
      "s3:*",
      "ecs:*",
      "iam:PassRole",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "gwangju-cicd-codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.gwangju-cicd-codepipeline_role.id
  policy = data.aws_iam_policy_document.gwangju-cicd-codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "gwangju-cicd-event" {
  name = "gwangju-ci-event"

  event_pattern = <<EOF
{
  "source": ["aws.codestar-connections"],
  "detail-type": ["CodeStarSourceConnection Repository State Change"],
  "resources": ["${aws_codestarconnections_connection.wlstmd.arn}"],
  "detail": {
    "repositoryName": ["wlstmd/gwangju-application-repo"],
    "branchName": ["master"],
    "referenceType": ["branch"],
    "actionName": ["Source"],
    "connectionArn": ["${aws_codestarconnections_connection.wlstmd.arn}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "gwangju-cicd-event" {
  target_id = "gwangju-ci-event-target"
  rule = aws_cloudwatch_event_rule.gwangju-cicd-event.name
  arn = aws_codepipeline.gwangju-cicd-pipeline.arn
  role_arn = aws_iam_role.gwangju-cicd-ci.arn
}

resource "aws_iam_role" "gwangju-cicd-ci" {
  name = "gwangju-ci"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "gwangju-cicd-ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "gwangju-cicd-ci" {
  name = "gwangju-ci-policy"
  policy = data.aws_iam_policy_document.gwangju-cicd-ci.json
}

resource "aws_iam_role_policy_attachment" "gwangju-cicd-ci" {
  policy_arn = aws_iam_policy.gwangju-cicd-ci.arn
  role = aws_iam_role.gwangju-cicd-ci.name
}

resource "aws_codestarconnections_connection" "wlstmd" {
  name          = "wlstmd"
  provider_type = "GitHub"
}