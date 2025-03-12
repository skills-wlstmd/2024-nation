resource "aws_security_group" "vpc2" {
  name = "gwangju-VPC2-Instance-sg"
  vpc_id = aws_vpc.vpc2.id

  ingress {
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-VPC2-Instance-sg"
  }
}