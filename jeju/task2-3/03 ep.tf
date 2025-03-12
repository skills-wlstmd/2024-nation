resource "aws_security_group" "connect" {
  name = "J-company-ep-SG"
  vpc_id = aws_vpc.main.id

  egress {
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }
  
  tags = {
    Name = "J-company-ep-SG"
  }
}

resource "aws_ec2_instance_connect_endpoint" "connect" {
  subnet_id = aws_subnet.private_a.id
  security_group_ids = [aws_security_group.connect.id]

  tags = {
    Name = "ec2-connect-endpoint"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "J-company-s3-endpoint"
  }
}

resource "aws_vpc_endpoint_policy" "s3" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowAll",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "*",
        "Resource" : "*"
      },
      {
        "Sid" : "DenySpecificS3Actions",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          "${aws_s3_bucket.s3_backup.arn}",
          "${aws_s3_bucket.s3_backup.arn}/*/*"
        ],
        "Condition" : {
          "StringNotEquals" : {
            "s3:prefix" : [
              "",
              "/"
            ]
          }
        }
      }
    ]
  })
}


resource "aws_vpc_endpoint_route_table_association" "s3_private_a" {
  route_table_id  = aws_route_table.private_a.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_vpc_endpoint_route_table_association" "s3_public_b" {
  route_table_id  = aws_route_table.public.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

resource "aws_security_group" "sqs" {
  name = "J-company-ep-sqs-SG"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }
    tags = {
    Name = "J-company-ep-sqs-SG"
  }
}

resource "aws_vpc_endpoint" "sqs" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.ap-northeast-2.sqs"
  vpc_endpoint_type = "Interface"
  security_group_ids = [
    aws_security_group.sqs.id
  ]
  private_dns_enabled = true
  tags = {
    Name = "J-company-sqs-endpoint"
  }
}

resource "aws_vpc_endpoint_subnet_association" "prod_a" {
  vpc_endpoint_id = aws_vpc_endpoint.sqs.id
  subnet_id       = aws_subnet.private_a.id
}

resource "aws_vpc_endpoint_subnet_association" "prod_b" {
  vpc_endpoint_id = aws_vpc_endpoint.sqs.id
  subnet_id       = aws_subnet.public_a.id
}