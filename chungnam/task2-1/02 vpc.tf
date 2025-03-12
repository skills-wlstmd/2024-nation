resource "aws_default_vpc" "default" {
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = ["${aws_default_vpc.default.id}"]
  }
}

resource "aws_default_route_table" "default_rt" {
  default_route_table_id = aws_default_vpc.default.default_route_table_id

  depends_on = [aws_default_vpc.default]
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "ap-northeast-2a"

  depends_on = [aws_default_vpc.default]
}


resource "aws_default_subnet" "default_az2" {
  availability_zone = "ap-northeast-2b"

  depends_on = [aws_default_vpc.default]
}


resource "aws_default_subnet" "default_az3" {
  availability_zone = "ap-northeast-2c"

  depends_on = [aws_default_vpc.default]
}


resource "aws_default_subnet" "default_az4" {
  availability_zone = "ap-northeast-2d"

  depends_on = [aws_default_vpc.default]
}

resource "aws_route_table_association" "default_az1" {
  subnet_id = aws_default_subnet.default_az1.id
  route_table_id = aws_default_route_table.default_rt.id
  depends_on = [aws_default_vpc.default]
}

resource "aws_route_table_association" "default_az2" {
  subnet_id = aws_default_subnet.default_az2.id
  route_table_id = aws_default_route_table.default_rt.id
  depends_on = [aws_default_vpc.default]
}

resource "aws_route_table_association" "default_az3" {
  subnet_id = aws_default_subnet.default_az3.id
  route_table_id = aws_default_route_table.default_rt.id
  depends_on = [aws_default_vpc.default]
}

resource "aws_route_table_association" "default_az4" {
  subnet_id = aws_default_subnet.default_az4.id
  route_table_id = aws_default_route_table.default_rt.id
  depends_on = [aws_default_vpc.default]
}

resource "aws_route" "default" {
  route_table_id = aws_default_route_table.default_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = data.aws_internet_gateway.default.id
}