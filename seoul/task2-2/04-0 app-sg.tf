data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "test" {
  name = "wsi-test-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "3306"
    to_port = "3306"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    from_port = 0
    to_port = 0
  }
 
    tags = {
    Name = "wsi-test-sg"
  }
}