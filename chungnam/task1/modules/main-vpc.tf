resource "aws_vpc" "ma" {
  cidr_block = "10.0.0.0/16"

  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "wsc2024-ma-vpc"
  }
}

resource"aws_internet_gateway" "ma" {
  vpc_id = aws_vpc.ma.id

  tags = {
    Name = "wsc2024-ma-mgmt-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ma.id

  tags = {
    Name = "wsc2024-ma-mgmt-rt"
  }
}
 
resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ma.id
}

resource "aws_route" "public_tgw_prod" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "172.16.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_vpc_attachment.ma ]
}

resource "aws_route" "public_tgw_storage" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "192.168.0.0/16"
  gateway_id = aws_ec2_transit_gateway.example.id
  depends_on = [ aws_ec2_transit_gateway.example,aws_ec2_transit_gateway_vpc_attachment.ma ]
}

resource "aws_subnet" "public_a" {
  vpc_id = aws_vpc.ma.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "${var.create_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-ma-mgmt-sn-a"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "public_b" {
  vpc_id = aws_vpc.ma.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "${var.create_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "wsc2024-ma-mgmt-sn-b"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_cloudwatch_log_group" "cw_group" {
    name = "wsc2024-ma-mgmt-log"
}

resource "aws_flow_log" "flow_log" {
    iam_role_arn = aws_iam_role.role.arn
    log_destination = aws_cloudwatch_log_group.cw_group.arn
    traffic_type = "ALL"
    vpc_id = aws_vpc.ma.id
    depends_on = [aws_cloudwatch_log_group.cw_group]
}


data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
    name = "wsc2024-ma-mgmt-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "role" {
  name   = "wsc2024-ma-mgmt-role"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.policy.json
}

data "aws_ami" "amazonlinux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*x86*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "wsc2024"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./wsc2024.pem"
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.amazonlinux2023.id
  subnet_id = aws_subnet.public_a.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    usermod -aG docker root
    chmod 666 /var/run/docker.sock
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    yum install -y curl jq
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv -f ./kubectl /usr/local/bin/kubectl
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    mv /tmp/eksctl /usr/bin
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sudo chmod 700 get_helm.sh
    ./get_helm.sh
    sudo mv ./get_helm.sh /usr/local/bin
    sudo dnf install -y mariadb105
    echo "Port 28282" >> /etc/ssh/sshd_config
    systemctl restart sshd
  EOF
  tags = {
    Name = "wsc2024-bastion-ec2"
  }
}

resource "aws_security_group" "bastion" {
  name = "wsc2024-bastion-sg"
  vpc_id = aws_vpc.ma.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "28282"
    to_port = "28282"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "443"
    to_port = "443"
  }

  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "3306"
    to_port = "3306"
  }

    tags = {
    Name = "wsc2024-bastion-sg"
  }
}

resource "aws_security_group" "lattice" {
  name = "wsc2024-lattice-sg"
  vpc_id = aws_vpc.ma.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "80"
    to_port = "80"
  }

  egress {
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
  }

    tags = {
    Name = "wsc2024-lattice-sg"
  }
}

resource "aws_iam_role" "bastion" {
  name = "wsc2024-bastion-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_iam_instance_profile" "bastion" {
  name = "wsc2024-ma-mgmt-profile-bastion"
  role = aws_iam_role.bastion.name
}