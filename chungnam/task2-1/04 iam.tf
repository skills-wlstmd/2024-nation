resource "aws_iam_role" "ssm-ec2" {
  name = "wsc2024-instance-role"
  
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

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}


resource "aws_iam_user" "Admin" {
    name          = "Admin"
    path          = "/"
    force_destroy = true

    tags = {
        Name = "Admin"
    }
}

resource "aws_iam_user_login_profile" "console_access_profile_Admin" {
    user      = aws_iam_user.Admin.name
    password_reset_required = true
    depends_on = [aws_iam_user.Admin]
}

resource "aws_iam_user_policy_attachment" "Admin-attach" {
  user       = aws_iam_user.Admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "Employee" {
    name          = "Employee"
    path          = "/"
    force_destroy = true

    tags = {
        Name = "Employee"
    }
}

resource "aws_iam_user_login_profile" "console_access_profile_Employee" {
    user      = aws_iam_user.Employee.name
    password_reset_required = true
    depends_on = [aws_iam_user.Employee]
}

resource "aws_iam_user_policy_attachment" "Employee-attach" {
  user       = aws_iam_user.Employee.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

output "Admin" {
    value = aws_iam_user_login_profile.console_access_profile_Admin.password
}

output "Employee" {
    value = aws_iam_user_login_profile.console_access_profile_Employee.password
}