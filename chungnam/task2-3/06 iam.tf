resource "aws_iam_role" "bastion" {
  name = "gm-bastion-role"
  
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
}

resource "aws_iam_instance_profile" "bastion" {
  name = "gm-bastion-role"
  role = aws_iam_role.bastion.name
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*","s3:*","elasticloadbalancing:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "policy" {
  name        = "s3-dynamodb-policy"
  policy      = data.aws_iam_policy_document.policy.json
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.policy.arn
}