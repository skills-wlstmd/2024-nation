resource "aws_iam_user" "user" {
    name = "wsi-project-user"
    path          = "/"
    force_destroy = true
    
    tags = {
        Name = "wsi-project-user"
    }
}

resource "aws_iam_user_policy_attachment" "user-admin" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_login_profile" "user" {
    user      = aws_iam_user.user.name
    password_reset_required = true
}

output "user_password" {
    value = aws_iam_user_login_profile.user.password
}