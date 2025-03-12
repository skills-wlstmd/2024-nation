resource "aws_vpc" "egress" {
  cidr_block = "172.22.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsc-egress-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "egress-igw" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "wsc-egress-igw"
  }
}

## Route Table
resource "aws_route_table" "egress" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "wsc-egress-pub-rt"
  }
}
 
resource "aws_route" "public" {
  route_table_id = aws_route_table.egress.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.egress-igw.id
}

resource "aws_route" "egress_tgw" {
  route_table_id = aws_route_table.egress.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

## Public Subnet
resource "aws_subnet" "egress-pub-a" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "172.22.0.32/28"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc-egress-pub-sn-a"
  }
}

resource "aws_subnet" "egress-pub-c" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "172.22.0.64/28"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc-egress-pub-sn-c"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "egress-pub-a" {
  subnet_id = aws_subnet.egress-pub-a.id
  route_table_id = aws_route_table.egress.id
}

resource "aws_route_table_association" "egress-pub-c" {
  subnet_id = aws_subnet.egress-pub-c.id
  route_table_id = aws_route_table.egress.id
}

# Private

## Elastic IP
resource "aws_eip" "private_a" {
}

resource "aws_eip" "private_b" {
}

## NAT Gateway
resource "aws_nat_gateway" "private_a" {

  allocation_id = aws_eip.private_a.id
  subnet_id = aws_subnet.egress-pub-a.id

  tags = {
    Name = "wsc-egress-ngw-a"
  }
}

resource "aws_nat_gateway" "private_c" {

  allocation_id = aws_eip.private_b.id
  subnet_id = aws_subnet.egress-pub-c.id

  tags = {
    Name = "wsc-egress-ngw-c"
  }
}

## Route Table
resource "aws_route_table" "egress-peering-a" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "wsc-egress-peering-a-rt"
  }
}

resource "aws_route_table" "egress-peering-c" {
  vpc_id = aws_vpc.egress.id

  tags = {
    Name = "wsc-egress-peering-c-rt"
  }
}

resource "aws_route" "private_a" {
  route_table_id = aws_route_table.egress-peering-a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_a.id
}

resource "aws_route" "private_c" {
  route_table_id = aws_route_table.egress-peering-c.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_c.id
}

resource "aws_subnet" "egress-peering-a" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "172.22.0.96/28"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsc-egress-peering-sn-a"
  }
}

resource "aws_subnet" "egress-peering-c" {
  vpc_id = aws_vpc.egress.id
  cidr_block = "172.22.0.128/28"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "wsc-egress-peering-sn-c"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "egress-peering-a" {
  subnet_id = aws_subnet.egress-peering-a.id
  route_table_id = aws_route_table.egress-peering-a.id
}

resource "aws_route_table_association" "egress-peering-c" {
  subnet_id = aws_subnet.egress-peering-c.id
  route_table_id = aws_route_table.egress-peering-c.id
}

resource "aws_route" "egress_a_tgw_inspect" {
  route_table_id = aws_route_table.egress-peering-a.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

resource "aws_route" "egress_c_tgw_inspect" {
  route_table_id = aws_route_table.egress-peering-c.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

# OutPut

## VPC
output "aws_vpc" {
  value = aws_vpc.egress.id
}

## Public Subnet
output "egress-pub-a" {
  value = aws_subnet.egress-pub-a.id
}

output "egress-pub-c" {
  value = aws_subnet.egress-pub-c.id
}

## Private Subnet
output "egress-peering-a" {
  value = aws_subnet.egress-peering-a.id
}

output "egress-peering-c" {
  value = aws_subnet.egress-peering-c.id
}