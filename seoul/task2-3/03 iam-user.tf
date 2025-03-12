resource "aws_iam_user" "tester" {
    name = "tester"
    path          = "/"
    force_destroy = true
    
    tags = {
        Name = "tester"
    }
}

resource "aws_iam_user_policy_attachment" "test-attach" {
  user       = aws_iam_user.tester.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_policy" "tester-policy" {
  name        = "mfaBucketDeleteControl"
  policy = "${file("./src/mfaBucketDeleteControl.json")}"
}

resource "aws_iam_group_policy" "regionAccessControl" {
  name  = "regionAccessControl"
  group = aws_iam_group.user_group_kr.name
  policy = "${file("./src/regionAccessControl.json")}"
}

resource "aws_iam_group" "user_group_kr" {
  name = "user_group_kr"
}

resource "aws_iam_group_membership" "user_group_kr" {
  name = "user_group_kr-membership"
  users = [aws_iam_user.tester.name]
  group = aws_iam_group.user_group_kr.name
}

resource "aws_iam_user_policy_attachment" "tester-attach" {
  user       = aws_iam_user.tester.name
  policy_arn = aws_iam_policy.tester-policy.arn
}

resource "aws_iam_user_login_profile" "tester" {
    user      = aws_iam_user.tester.name
    password_reset_required = true
}

output "tester_password" {
    value = aws_iam_user_login_profile.tester.password
}