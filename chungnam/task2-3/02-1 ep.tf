resource "aws_vpc_endpoint" "db" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.dynamodb"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "dynamodb-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_a" {
  route_table_id  = aws_route_table.private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.db.id
}

resource "aws_vpc_endpoint_route_table_association" "private_b" {
  route_table_id  = aws_route_table.private_b.id
  vpc_endpoint_id = aws_vpc_endpoint.db.id
}

resource "aws_vpc_endpoint_policy" "example" {
  vpc_endpoint_id = aws_vpc_endpoint.db.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "dynamodb:*"
        ],
        "Resource" : ["${aws_dynamodb_table.dynamodb.arn}"]
      }
    ]
  })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"
  tags = {
    Name = "s3-endpoint"
  }
}

resource "aws_vpc_endpoint_route_table_association" "s3_private_a" {
  route_table_id  = aws_route_table.private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_private_b" {
  route_table_id  = aws_route_table.private_b.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}


resource "aws_security_group" "ep-sg" {
  name = "ep-sg"
  vpc_id = aws_vpc.main.id
  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }
  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }
    tags = {
    Name = "ep-sg"
  }
}

resource "aws_vpc_endpoint" "elb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.elasticloadbalancing"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.ep-sg.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "elb-endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "elb-private_a" {
  vpc_endpoint_id = aws_vpc_endpoint.elb.id
  subnet_id  = aws_subnet.private_a.id
}

resource "aws_vpc_endpoint_subnet_association" "elb-private_b" {
  vpc_endpoint_id = aws_vpc_endpoint.elb.id
  subnet_id  = aws_subnet.private_b.id
}