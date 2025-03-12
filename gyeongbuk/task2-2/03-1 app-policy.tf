resource "random_string" "app_random" {
  length           = 5
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

## IAM
resource "aws_iam_role" "app" {
  name = "wsi-role-app"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "app" {
  name = "wsi-profile-app${random_string.app_random.result}"
  role = aws_iam_role.app.name
}