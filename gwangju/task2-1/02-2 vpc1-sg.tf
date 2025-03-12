resource "aws_security_group" "vpc1" {
  name = "gwangju-VPC1-Instance-sg"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    protocol = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = -1
    to_port = -1
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "gwangju-VPC1-Instance-sg"
  }
}