resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "apdev-vpc"
  }
}

resource"aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "apdev-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "apdev-public-rt"
  }
}
 
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "apdev-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "apdev-public-b"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "app_a" {
}

resource "aws_eip" "app_b" {
}

resource "aws_nat_gateway" "app_a" {
  depends_on = [aws_internet_gateway.main]

  allocation_id = aws_eip.app_a.id
  subnet_id = aws_subnet.public_a.id

  tags = {
    Name = "apdev-natgw-a"
  }
}

resource "aws_nat_gateway" "app_b" {
  depends_on = [aws_internet_gateway.main]

  allocation_id = aws_eip.app_b.id
  subnet_id = aws_subnet.public_b.id

  tags = {
    Name = "apdev-natgw-b"
  }
}

resource "aws_route_table" "app_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "apdev-app-a-rt"
  }
}

resource "aws_route_table" "app_b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "apdev-app-b-rt"
  }
}

resource "aws_route" "app_a" {
  route_table_id = aws_route_table.app_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.app_a.id
}

resource "aws_route" "app_b" {
  route_table_id = aws_route_table.app_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.app_b.id
}

resource "aws_subnet" "app_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "apdev-app-a"
  }
}

resource "aws_subnet" "app_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "apdev-app-b"
  }
}

resource "aws_route_table_association" "app_a" {
  subnet_id = aws_subnet.app_a.id
  route_table_id = aws_route_table.app_a.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id = aws_subnet.app_b.id
  route_table_id = aws_route_table.app_b.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "apdev-data-rt"
  }
}

resource "aws_subnet" "data_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "apdev-data-a"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "apdev-data-b"
  }
}

resource "aws_route_table_association" "data_a" {
  subnet_id = aws_subnet.data_a.id
  route_table_id = aws_route_table.data.id
}

resource "aws_route_table_association" "data_b" {
  subnet_id = aws_subnet.data_b.id
  route_table_id = aws_route_table.data.id
}