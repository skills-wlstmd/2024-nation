resource "aws_vpc" "gwangju-cicd-main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "gwangju-vpc"
  }
}

resource"aws_internet_gateway" "gwangju-cicd-main" {
  vpc_id = aws_vpc.gwangju-cicd-main.id

  tags = {
    Name = "gwangju-igw"
  }
}

resource "aws_route_table" "gwangju-cicd-public" {
  vpc_id = aws_vpc.gwangju-cicd-main.id

  tags = {
    Name = "gwangju-public-rt"
  }
}
 
resource "aws_route" "gwangju-cicd-public" {
  route_table_id = aws_route_table.gwangju-cicd-public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gwangju-cicd-main.id
}

resource "aws_subnet" "gwangju-cicd-public_a" {
  vpc_id = aws_vpc.gwangju-cicd-main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "gwangju-public-a"
  }
}

resource "aws_subnet" "gwangju-cicd-public_b" {
  vpc_id = aws_vpc.gwangju-cicd-main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "gwangju-public-b"
  }
}

resource "aws_route_table_association" "gwangju-cicd-public_a" {
  subnet_id = aws_subnet.gwangju-cicd-public_a.id
  route_table_id = aws_route_table.gwangju-cicd-public.id
}

resource "aws_route_table_association" "gwangju-cicd-public_b" {
  subnet_id = aws_subnet.gwangju-cicd-public_b.id
  route_table_id = aws_route_table.gwangju-cicd-public.id
}

resource "aws_eip" "gwangju-cicd-private_a" {
}

resource "aws_eip" "gwangju-cicd-private_b" {
}

resource "aws_nat_gateway" "gwangju-cicd-private_a" {
  depends_on = [aws_internet_gateway.gwangju-cicd-main]

  allocation_id = aws_eip.gwangju-cicd-private_a.id
  subnet_id = aws_subnet.gwangju-cicd-public_a.id

  tags = {
    Name = "gwangju-ngw-a"
  }
}

resource "aws_nat_gateway" "gwangju-cicd-private_b" {
  depends_on = [aws_internet_gateway.gwangju-cicd-main]

  allocation_id = aws_eip.gwangju-cicd-private_b.id
  subnet_id = aws_subnet.gwangju-cicd-public_b.id

  tags = {
    Name = "gwangju-ngw-b"
  }
}

resource "aws_route_table" "gwangju-cicd-private_a" {
  vpc_id = aws_vpc.gwangju-cicd-main.id

  tags = {
    Name = "gwangju-private-a-rt"
  }
}

resource "aws_route_table" "gwangju-cicd-private_b" {
  vpc_id = aws_vpc.gwangju-cicd-main.id

  tags = {
    Name = "gwangju-private-b-rt"
  }
}

resource "aws_route" "gwangju-cicd-private_a" {
  route_table_id = aws_route_table.gwangju-cicd-private_a.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gwangju-cicd-private_a.id
}

resource "aws_route" "gwangju-cicd-private_b" {
  route_table_id = aws_route_table.gwangju-cicd-private_b.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gwangju-cicd-private_b.id
}

resource "aws_subnet" "gwangju-cicd-private_a" {
  vpc_id = aws_vpc.gwangju-cicd-main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name = "gwangju-private-a"
  }
}

resource "aws_subnet" "gwangju-cicd-private_b" {
  vpc_id = aws_vpc.gwangju-cicd-main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name = "gwangju-private-b"
  }
}

resource "aws_route_table_association" "gwangju-cicd-private_a" {
  subnet_id = aws_subnet.gwangju-cicd-private_a.id
  route_table_id = aws_route_table.gwangju-cicd-private_a.id
}

resource "aws_route_table_association" "gwangju-cicd-private_b" {
  subnet_id = aws_subnet.gwangju-cicd-private_b.id
  route_table_id = aws_route_table.gwangju-cicd-private_b.id
}