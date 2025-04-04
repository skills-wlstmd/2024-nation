resource "aws_security_group" "ecs" {
  name = "wsi-ecs-sg"
  vpc_id = aws_vpc.main.id
  
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
    Name = "wsi-ecs-sg"
  }

  lifecycle {
    ignore_changes = [ingress, egress]
  }
}