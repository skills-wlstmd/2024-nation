resource "aws_security_group" "vpc1-endpiont" {
  name = "gwangju-vpc1-endpiont-sg"
  vpc_id = aws_vpc.vpc1.id

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
    Name = "gwangju-vpc1-endpiont-sg"
  }
}

resource "aws_vpc_endpoint" "ssm-1" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.ap-northeast-2.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssm-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-1.id
  subnet_id       = aws_subnet.private_b-1.id
}

resource "aws_vpc_endpoint" "ssm-message-1" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.ap-northeast-2.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ssmmessages-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ssm-message-1.id
  subnet_id       = aws_subnet.private_b-1.id
}

resource "aws_vpc_endpoint" "ec2-1" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-1.id
  subnet_id       = aws_subnet.private_b-1.id
}
resource "aws_vpc_endpoint" "ec2-message-1" {
  vpc_id            = aws_vpc.vpc1.id
  service_name      = "com.amazonaws.ap-northeast-2.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc1-endpiont.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "gwangju-ec2-message-endpoint-1"
  }
}

resource "aws_vpc_endpoint_subnet_association" "sub-a-ec2-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-1.id
  subnet_id       = aws_subnet.private_a-1.id
}
resource "aws_vpc_endpoint_subnet_association" "sub-b-ec2-message-1" {
  vpc_endpoint_id = aws_vpc_endpoint.ec2-message-1.id
  subnet_id       = aws_subnet.private_b-1.id
}