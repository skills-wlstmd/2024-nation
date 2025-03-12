resource "aws_ec2_transit_gateway" "gwangju" {
  description = "example"
  auto_accept_shared_attachments = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support = "enable"
  multicast_support = "enable"
  vpn_ecmp_support = "enable"
  tags = {
    Name = "gwangju-vpc-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "egress" {
  subnet_ids         = [aws_subnet.egress-private_a.id,aws_subnet.egress-private_b.id]
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  vpc_id             = aws_vpc.egress.id
  tags = {
    Name = "gwangju-egress-tgw-attache"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "VPC-1" {
  subnet_ids         = [aws_subnet.private_a-1.id, aws_subnet.private_b-1.id]
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  vpc_id             = aws_vpc.vpc1.id
  tags = {
    Name = "gwangju-vpc-1-tgw-attache"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "VPC-2" {
  subnet_ids         = [aws_subnet.private_b-2.id,aws_subnet.private_a-2.id]
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  vpc_id             = aws_vpc.vpc2.id
  tags = {
    Name = "gwangju-vpc-2-tgw-attache"
  }
}

resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  tags = {
    Name = "gwangju-egress-tgw-rt"
  }
}
resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}
resource "aws_ec2_transit_gateway_route" "egress-vpc1-route" {
  destination_cidr_block         = "10.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route" "egress-vpc2-route" {
  destination_cidr_block         = "10.0.1.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.egress.id
}

resource "aws_ec2_transit_gateway_route_table" "VPC1" {
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  tags = {
    Name = "gwangju-VPC1-tgw-rt"
  }
}
resource "aws_ec2_transit_gateway_route_table_association" "VPC-1" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC1.id
}
resource "aws_ec2_transit_gateway_route" "vpc1-egress-route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC1.id
}

resource "aws_ec2_transit_gateway_route" "vpc1-vpc2-route" {
  destination_cidr_block         = "10.0.1.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC1.id
}

resource "aws_ec2_transit_gateway_route_table" "VPC2" {
  transit_gateway_id = aws_ec2_transit_gateway.gwangju.id
  tags = {
    Name = "gwangju-VPC2-tgw-rt"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "VPC-2" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC2.id
}

resource "aws_ec2_transit_gateway_route" "vpc2-egress-route" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.egress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC2.id
}

resource "aws_ec2_transit_gateway_route" "vpc2-vpc1-route" {
  destination_cidr_block         = "10.0.0.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-1.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC2.id
}
resource "aws_ec2_transit_gateway_route" "vpc2-egress-black-route" {
  destination_cidr_block         = "10.0.2.0/24"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.VPC-2.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.VPC2.id
}