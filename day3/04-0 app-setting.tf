# resource "aws_security_group" "app" {
#   name = "apdev-app-sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port = "22"
#     to_port = "22"
#   }

#   ingress {
#     protocol = "tcp"
#     security_groups   = [aws_security_group.alb.id]
#     from_port = "8080"
#     to_port = "8080"
#   }

#   egress {
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port = "80"
#     to_port = "80"
#   }
 
#   egress {
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port = "443"
#     to_port = "443"
#   }

#     tags = {
#     Name = "apdev-app-sg"
#   }
# }


# resource "aws_iam_role" "app" {
#   name = "apdev-app-role"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Sid = ""
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })

#   managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
# }

# resource "aws_iam_instance_profile" "app" {
#   name = "apdev-profile-app"
#   role = aws_iam_role.app.name
# }