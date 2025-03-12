resource "aws_security_group" "egress" {
  name = "gwangju-EgressVPC-Instance-sg"
  vpc_id = aws_vpc.egress.id

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
    Name = "gwangju-EgressVPC-Instance-sg"
  }
}