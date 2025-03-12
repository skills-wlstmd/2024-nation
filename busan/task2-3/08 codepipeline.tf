resource "random_string" "cicd_random" {
  length           = 3
  upper   = false
  lower   = false
  numeric  = true
  special = false
}

resource "aws_codepipeline" "pipeline" {
  name     = "wsi-pipeline"
  pipeline_type = "V2"
  execution_mode = "QUEUED"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline.bucket
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
        FullRepositoryId = "wlstmd/wsi-repo"
        BranchName = "main"
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
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "Deploy"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "CodeDeploy"
      input_artifacts  = ["build_output"]
      version          = "1"

      configuration = {
        ApplicationName       = aws_codedeploy_app.app.name
        DeploymentGroupName   = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
  depends_on = [aws_instance.app]
}

resource "aws_s3_bucket" "pipeline" {
  bucket_prefix = "wsi-artifacts-${random_string.cicd_random.result}"
  force_destroy = true
}


data "aws_iam_policy_document" "assume_role_pipeline" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "wsi-role-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.assume_role_pipeline.json
}

data "aws_iam_policy_document" "codepipeline_policy" {
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

resource "aws_iam_role_policy" "codepipeline_policy" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline_role.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_cloudwatch_event_rule" "event" {
  name = "wsi-ci-event"

  event_pattern = <<EOF
{
  "source": ["aws.codestar-connections"],
  "detail-type": ["CodeStarSourceConnection Repository State Change"],
  "resources": ["${aws_codestarconnections_connection.wlstmd.arn}"],
  "detail": {
    "repositoryName": ["wlstmd/wsi-repo"],
    "branchName": ["main"],
    "referenceType": ["branch"],
    "actionName": ["Source"],
    "connectionArn": ["${aws_codestarconnections_connection.wlstmd.arn}"]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "event" {
  target_id = "wsi-ci-event-target"
  rule = aws_cloudwatch_event_rule.event.name
  arn = aws_codepipeline.pipeline.arn
  role_arn = aws_iam_role.ci.arn
}

resource "aws_iam_role" "ci" {
  name = "wsi-ci"
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

data "aws_iam_policy_document" "ci" {
  statement {
    actions = [
      "iam:PassRole",
      "codepipeline:*"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "ci" {
  name = "wsi-ci-policy"
  policy = data.aws_iam_policy_document.ci.json
}

resource "aws_iam_role_policy_attachment" "ci" {
  policy_arn = aws_iam_policy.ci.arn
  role = aws_iam_role.ci.name
}

resource "aws_codestarconnections_connection" "wlstmd" {
  name          = "wlstmd"
  provider_type = "GitHub"
}