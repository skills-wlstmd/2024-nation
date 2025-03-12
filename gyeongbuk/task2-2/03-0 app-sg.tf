resource "aws_security_group" "app" {
  name = "wsi-token-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.bastion.id]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.lb.id]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }

  tags = {
    Name = "wsi-token-sg"
  }
}