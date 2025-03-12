resource "aws_vpc" "main" {
  cidr_block = "210.89.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "J-company-vpc"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "J-company-priv-a-rt"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "210.89.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "J-company-priv-sub-a"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "J-company-priv-b-rt"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id = aws_vpc.main.id
  cidr_block = "210.89.0.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "J-company-priv-sub-b"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}