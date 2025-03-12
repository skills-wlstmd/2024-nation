resource "aws_vpc" "ingress" {
  cidr_block = "172.20.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsc-ingress-vpc"
  }
}

# Public
## Internet Gateway
resource"aws_internet_gateway" "ingress" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "wsc-ingress-pub-igw"
  }
}

## Route Table
resource "aws_route_table" "ingress" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "wsc-ingress-pub-rt"
  }
}
 
resource "aws_route" "ingress" {
  route_table_id = aws_route_table.ingress.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ingress.id
}

resource "aws_route" "ingress-tgw" {
  route_table_id = aws_route_table.ingress.id
  destination_cidr_block = "10.100.0.0/16"
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

## Public Subnet
resource "aws_subnet" "ingress-pub-a" {
  vpc_id = aws_vpc.ingress.id
  cidr_block = "172.20.0.32/28"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc-ingress-pub-sn-a"
  }
}

resource "aws_subnet" "ingress-pub-c" {
  vpc_id = aws_vpc.ingress.id
  cidr_block = "172.20.0.64/28"
  availability_zone = "ap-northeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc-ingress-pub-sn-c"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "ingress-pub-a" {
  subnet_id = aws_subnet.ingress-pub-a.id
  route_table_id = aws_route_table.ingress.id
}

resource "aws_route_table_association" "ingress-pub-c" {
  subnet_id = aws_subnet.ingress-pub-c.id
  route_table_id = aws_route_table.ingress.id
}

## Route Table
resource "aws_route_table" "ingress-peering-a" {
  vpc_id = aws_vpc.ingress.id

  tags = {
    Name = "wsc-ingress-peering-rt"
  }
}

resource "aws_subnet" "ingress-peering-a" {
  vpc_id = aws_vpc.ingress.id
  cidr_block = "172.20.0.96/28"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "wsc-ingress-peering-sn-a"
  }
}

resource "aws_subnet" "ingress-peering-c" {
  vpc_id = aws_vpc.ingress.id
  cidr_block = "172.20.0.128/28"
  availability_zone = "ap-northeast-2c"

  tags = {
    Name = "wsc-ingress-peering-sn-c"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "ingress-peering-a" {
  subnet_id = aws_subnet.ingress-peering-a.id
  route_table_id = aws_route_table.ingress-peering-a.id
}

resource "aws_route_table_association" "ingress-peering-c" {
  subnet_id = aws_subnet.ingress-peering-c.id
  route_table_id = aws_route_table.ingress-peering-a.id
}

resource "aws_route" "ingress_tgw_inspect" {
  route_table_id = aws_route_table.ingress-peering-a.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id = aws_ec2_transit_gateway.example.id
}

resource "aws_security_group" "ingress-lb-sg" {
  name = "wsc-ingress-alb-SG"
  vpc_id = aws_vpc.ingress.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }
  egress {
    protocol = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }

    tags = {
    Name = "wsc-ingress-alb-SG"
  }
}

# OutPut

## VPC
output "aws_ingress_vpc" {
  value = aws_vpc.ingress.id
}

## Public Subnet
output "ingress_public_a" {
  value = aws_subnet.ingress-pub-a.id
}

output "ingress_public_c" {
  value = aws_subnet.ingress-pub-c.id
}

## Private Subnet
output "ingress_peering_a" {
  value = aws_subnet.ingress-peering-a.id
}

output "ingress_peering_c" {
  value = aws_subnet.ingress-peering-c.id
}