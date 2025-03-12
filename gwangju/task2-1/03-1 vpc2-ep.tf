resource "aws_security_group" "vpc-2-endpiont" {
  name = "gwangju-vpc2-endpiont-sg"
  vpc_id = aws_vpc.vpc2.id

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
    Name = "gwangju-vpc2-endpiont-sg"
  }
}

resource "aws_vpc_endpoint" "ssm-2" {
  vpc_id            = aws_vpc.vpc2.id
  service_name      = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssm-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-2.id
  subnet_id       = aws_subnet.private_b-2.id
}

resource "aws_vpc_endpoint" "ssm-message-2" {
  vpc_id            = aws_vpc.vpc2.id
  service_name      = "com.amazonaws.ap-northeast-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssmmessages-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-2.id
  subnet_id       = aws_subnet.private_b-2.id
}

resource "aws_vpc_endpoint" "ec2-2" {
  vpc_id            = aws_vpc.vpc2.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-2.id
  subnet_id       = aws_subnet.private_a-2.id
}

resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-2.id
  subnet_id       = aws_subnet.private_b-2.id
}
resource "aws_vpc_endpoint" "ec2-message-2" {
  vpc_id            = aws_vpc.vpc2.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc-2-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-message-endpoint-2"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-2.id
  subnet_id       = aws_subnet.private_a-2.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-message-2" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-2.id
  subnet_id       = aws_subnet.private_b-2.id
}