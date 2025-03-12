resource "aws_security_group" "ecs" {
  name = "wsc2024-ecs-sg"
  vpc_id = aws_default_vpc.default.id
  
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
  
  tags = {
    Name = "wsc2024-ecs-sg"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}