resource "aws_vpc" "vpc1" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-VPC1"
  }
}

resource "aws_route_table" "private_a-1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "gwangju-private-a-1-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_subnet" "private_a-1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.0.0/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-private-1-a"
  }
}

resource "aws_route_table_association" "private_a-1" {
  subnet_id = aws_subnet.private_a-1.id
  route_table_id = aws_route_table.private_a-1.id
}

resource "aws_route" "vpc1-egress-pri-a-tgw" {
  route_table_id = aws_route_table.private_a-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_route_table" "private_b-1" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "gwangju-private-1-b-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_subnet" "private_b-1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.0.128/25"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-private-1-b"
  }
}

resource "aws_route_table_association" "private_b-1" {
  subnet_id = aws_subnet.private_b-1.id
  route_table_id = aws_route_table.private_b-1.id
}
resource "aws_route" "vpc1-egress-pri-b-tgw" {
  route_table_id = aws_route_table.private_b-1.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}