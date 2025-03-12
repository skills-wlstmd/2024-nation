resource "aws_iam_role" "code-deploy-Role" {
  name = "code-deploy-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole","arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
  tags = {
    Name = "code-deploy-Role"
  }
}

resource "aws_codedeploy_app" "app" {
  compute_platform = "Server"
  name             = "wsi-app"
}

resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "wsi-dg"
  service_role_arn      = aws_iam_role.code-deploy-Role.arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "wsi-server"
    }
  }
  outdated_instances_strategy = "UPDATE"
}