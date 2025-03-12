resource "aws_vpc" "prod" {
  cidr_block = "172.16.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsc2024-prod-vpc"
  }
}

# Public

## Internet Gateway
resource"aws_internet_gateway" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-igw"
  }
}

## Route Table
resource "aws_route_table" "prod" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-load-rt"
  }
}
 
resource "aws_route" "prod" {
  route_table_id = aws_route_table.prod.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.prod.id
}

resource "aws_route" "prod_tgw_ma" {
  route_table_id = aws_route_table.prod.id
  destination_cidr_block = "10.0.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

resource "aws_route" "prod_tgw_storage_ma" {
  route_table_id = aws_route_table.prod.id
  destination_cidr_block = "192.168.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

## prod Subnet
resource "aws_subnet" "prod_a" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "172.16.0.0/24"
  availability_zone = "${var.create_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-prod-load-sn-a"
  }
}

resource "aws_subnet" "prod_b" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "172.16.1.0/24"
  availability_zone = "${var.create_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-prod-load-sn-b"
  }
}

## Attach Public Subnet in Route Table
resource "aws_route_table_association" "prod_a" {
  subnet_id = aws_subnet.prod_a.id
  route_table_id = aws_route_table.prod.id
}

resource "aws_route_table_association" "prod_b" {
  subnet_id = aws_subnet.prod_b.id
  route_table_id = aws_route_table.prod.id
}

# Private

## Elastic IP
resource "aws_eip" "private_a" {
}

resource "aws_eip" "private_b" {
}

## NAT Gateway
resource "aws_nat_gateway" "private_a" {
  depends_on = [aws_internet_gateway.prod]

  allocation_id = aws_eip.private_a.id
  subnet_id = aws_subnet.prod_a.id

  tags = {
    Name = "wsc2024-prod-natgw-a"
  }
}

resource "aws_nat_gateway" "private_b" {
  depends_on = [aws_internet_gateway.prod]

  allocation_id = aws_eip.private_b.id
  subnet_id = aws_subnet.prod_b.id

  tags = {
    Name = "wsc2024-prod-natgw-b"
  }
}

## Route Table
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-app-rt-a"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "wsc2024-prod-app-rt-b"
  }
}

resource "aws_route" "private_a" {
  route_table_id = aws_route_table.private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_a.id
}

resource "aws_route" "private_b" {
  route_table_id = aws_route_table.private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.private_b.id
}

resource "aws_route" "main_prod_tgw_ma" {
  route_table_id = aws_route_table.private_a.id
  destination_cidr_block = "10.0.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

resource "aws_route" "prod_tgw_storage" {
  route_table_id = aws_route_table.private_a.id
  destination_cidr_block = "192.168.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

resource "aws_route" "main_private_tgw_ma" {
  route_table_id = aws_route_table.private_b.id
  destination_cidr_block = "10.0.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

resource "aws_route" "private_prod_tgw_storage" {
  route_table_id = aws_route_table.private_b.id
  destination_cidr_block = "192.168.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_route.prod-ma-rt,aws_ec2_transit_gateway_route.prod-storage-rt ]
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "172.16.2.0/24"
  availability_zone = "${var.create_region}a"

  tags = {
    Name = "wsc2024-prod-app-sn-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id = aws_vpc.prod.id
  cidr_block = "172.16.3.0/24"
  availability_zone = "${var.create_region}b"

  tags = {
    Name = "wsc2024-prod-app-sn-b"
  }
}

## Attach Private Subnet in Route Table
resource "aws_route_table_association" "private_a" {
  subnet_id = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
}