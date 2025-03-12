resource "aws_security_group" "alb" {
  name = "wsc2024-alb-sg"
  vpc_id = aws_default_vpc.default.id
  
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
  
  tags = {
    Name = "wsc2024-alb-sg"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}