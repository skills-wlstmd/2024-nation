resource "aws_vpc" "egress" {
  cidr_block = "10.0.2.0/24"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-EgressVPC"
  }
}

resource"aws_internet_gateway" "egress" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "gwangju-egress-igw"
  }
}

resource "aws_route_table" "egress-public" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "gwangju-egress-public-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}
 
resource "aws_route" "egress-public" {
  route_table_id = aws_route_table.egress-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.egress.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}

resource "aws_route" "egress-vpc1-pub-tgw" {
  route_table_id = aws_route_table.egress-public.id
  destination_cidr_block = "10.0.0.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}
resource "aws_route" "egress-vpc2-pub-vpc2-tgw" {
  route_table_id = aws_route_table.egress-public.id
  destination_cidr_block = "10.0.1.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}


resource "aws_subnet" "egress-public_a" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "10.0.2.0/25"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "gwangju-egress-public-a"
  }
}

resource "aws_route_table_association" "egress-public_a" {
  subnet_id = aws_subnet.egress-public_a.id
  route_table_id = aws_route_table.egress-public.id
}

resource "aws_eip" "egress-private_a" {
}

resource "aws_eip" "egress-private_b" {
}

resource "aws_nat_gateway" "egress-private_a" {
  depends_on = [aws_internet_gateway.egress]

  allocation_id = aws_eip.egress-private_a.id
  subnet_id = aws_subnet.egress-public_a.id

  tags = {
    Name = "gwangju-egress-ngw-a"
  }
}

resource "aws_nat_gateway" "egress-private_b" {
  depends_on = [aws_internet_gateway.egress]

  allocation_id = aws_eip.egress-private_b.id
  subnet_id = aws_subnet.egress-public_a.id

  tags = {
    Name = "gwangju-egress-ngw-b"
  }
}

## Route Table
resource "aws_route_table" "egress-private_a" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "gwangju-egress-private-a-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_route" "egress-private_a" {
  route_table_id = aws_route_table.egress-private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.egress-private_a.id
}

resource "aws_route" "egress-vpc1-pri-a-tgw" {
  route_table_id = aws_route_table.egress-private_a.id
  destination_cidr_block = "10.0.0.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}
resource "aws_route" "egress-vpc2-pri-a-tgw" {
  route_table_id = aws_route_table.egress-private_a.id
  destination_cidr_block = "10.0.1.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}


resource "aws_route_table" "egress-private_b" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "gwangju-egress-private-b-rt"
  }
  depends_on = [ aws_ec2_transit_gateway.gwangju ]
}

resource "aws_route" "egress-private_b" {
  route_table_id = aws_route_table.egress-private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.egress-private_b.id
}

resource "aws_route" "egress-vpc1-pri-b-tgw" {
  route_table_id = aws_route_table.egress-private_b.id
  destination_cidr_block = "10.0.0.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}
resource "aws_route" "egress-vpc2-pri-b-tgw" {
  route_table_id = aws_route_table.egress-private_b.id
  destination_cidr_block = "10.0.1.0/24"
  gateway_id = aws_ec2_transit_gateway.gwangju.id
  depends_on = [ aws_ec2_transit_gateway.gwangju,aws_ec2_transit_gateway_route_table_association.egress ]
}

resource "aws_subnet" "egress-private_a" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "10.0.2.128/26"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-egress-private-a"
  }
  
}

resource "aws_subnet" "egress-private_b" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "10.0.2.192/26"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-egress-private-b"
  }
}

resource "aws_route_table_association" "egress-private_a" {
  subnet_id = aws_subnet.egress-private_a.id
  route_table_id = aws_route_table.egress-private_a.id
}

resource "aws_route_table_association" "egress-private_b" {
  subnet_id = aws_subnet.egress-private_b.id
  route_table_id = aws_route_table.egress-private_b.id
}