resource "aws_iam_user" "user1" {
    name = "wsi-project-user1"
    path          = "/"
    force_destroy = true
    
    tags = {
        Name = "wsi-project-user1"
    }
}

resource "aws_iam_user_policy_attachment" "user1" {
  user       = aws_iam_user.user1.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_user_policy" "user1-policy" {
  name   = "user1-policy"
  user   = aws_iam_user.user1.name

  policy = "${file("./src/user1.json")}"
}


resource "aws_iam_user_login_profile" "user1" {
    user      = aws_iam_user.user1.name
    password_reset_required = true
}

output "user1_password" {
    value = aws_iam_user_login_profile.user1.password
}