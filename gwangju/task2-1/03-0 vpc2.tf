resource "aws_vpc" "vpc2" {
  cidr_block = "10.0.1.0/24"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-VPC2"
  }
}

resource "aws_route_table" "private_a-2" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "gwangju-private-a-2-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.VPC-2 ]
}

resource "aws_subnet" "private_a-2" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "10.0.1.0/25"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-private-2-a"
  }
}

resource "aws_route_table_association" "private_a-2" {
  subnet_id = aws_subnet.private_a-2.id
  route_table_id = aws_route_table.private_a-2.id
}
resource "aws_route" "vpc2-egress-pri-a-tgw" {
  route_table_id = aws_route_table.private_a-2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_route_table" "private_b-2" {
  vpc_id = aws_vpc.vpc2.id

  tags = {
    Name = "gwangju-private-2-b-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}
resource "aws_subnet" "private_b-2" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "10.0.1.128/25"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-private-2-b"
  }
}

resource "aws_route_table_association" "private_b-2" {
  subnet_id = aws_subnet.private_b-2.id
  route_table_id = aws_route_table.private_b-2.id
}

resource "aws_route" "vpc2-egress-pri-b-tgw" {
  route_table_id = aws_route_table.private_b-2.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.VPC-2 ]
}