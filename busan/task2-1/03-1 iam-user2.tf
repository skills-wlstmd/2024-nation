resource "aws_iam_user" "user2" {
    name = "wsi-project-user2"
    path          = "/"
    force_destroy = true
    
    tags = {
        Name = "wsi-project-user2"
    }
}

resource "aws_iam_user_policy_attachment" "user2" {
  user       = aws_iam_user.user2.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_user_policy" "user2-policy" {
  name   = "user2-policy"
  user   = aws_iam_user.user2.name
  policy = "${file("./src/user2.json")}"
}

resource "aws_iam_user_login_profile" "user2" {
    user      = aws_iam_user.user2.name
    password_reset_required = true
}

output "user2_password" {
    value = aws_iam_user_login_profile.user2.password
}