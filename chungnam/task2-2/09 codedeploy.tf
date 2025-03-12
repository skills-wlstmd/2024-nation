data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "chungnam_assume_by_codedeploy" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "chungnam_codedeploy" {
  name               = "codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.chungnam_assume_by_codedeploy.json
}

data "aws_iam_policy_document" "basic_codedeploy_policy" {
  statement {
    sid    = "AllowBasicActions"
    effect = "Allow"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "s3:GetObject",
      "iam:PassRole",
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "basic_codedeploy_policy" {
  name   = "basic-codedeploy-policy"
  policy = data.aws_iam_policy_document.basic_codedeploy_policy.json
}

resource "aws_iam_role_policy_attachment" "basic_codedeploy_policy_attachment" {
  role       = aws_iam_role.chungnam_codedeploy.name
  policy_arn = aws_iam_policy.basic_codedeploy_policy.arn
}

resource "aws_codedeploy_app" "deploy" {
  compute_platform = "ECS"
  name             = "wsc2024-cdy"
}

resource "aws_codedeploy_deployment_group" "deploy" {
  app_name               = aws_codedeploy_app.deploy.name
  deployment_group_name  = "lb-cdy-group"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  service_role_arn       = aws_iam_role.chungnam_codedeploy.arn

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 1
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.svc.name
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.lb.arn]
      }

      target_group {
        name = aws_alb_target_group.tg1.name
      }

      target_group {
        name = aws_alb_target_group.tg2.name
      }
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_codedeploy_policy_attachment
  ]
}

data "aws_iam_policy_document" "full_codedeploy_policy" {
  statement {
    sid    = "AllowLoadBalancingAndECSModifications"
    effect = "Allow"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "cloudwatch:DescribeAlarms",
      "s3:GetObjectVersion",
      "s3:GetObject"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "DeployService"
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "codedeploy:GetDeploymentGroup",
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = [
      aws_ecs_service.svc.id,
      aws_codedeploy_deployment_group.deploy.arn,
      "arn:aws:codedeploy:us-west-1:${data.aws_caller_identity.current.account_id}:deploymentconfig:*",
      aws_codedeploy_app.deploy.arn
    ]
  }
}

resource "aws_iam_policy" "full_codedeploy_policy" {
  name   = "full-codedeploy-policy"
  policy = data.aws_iam_policy_document.full_codedeploy_policy.json

  depends_on = [
    aws_codedeploy_deployment_group.deploy
  ]
}

resource "aws_iam_role_policy_attachment" "full_codedeploy_policy_attachment" {
  role       = aws_iam_role.chungnam_codedeploy.name
  policy_arn = aws_iam_policy.full_codedeploy_policy.arn

  depends_on = [
    aws_iam_policy.full_codedeploy_policy
  ]
}