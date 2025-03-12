data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.latest_ami.value
  subnet_id = aws_subnet.public_a.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y curl jq --allowerasing
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    mv /tmp/eksctl /usr/bin
    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.3/2024-04-19/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    mv ./kubectl /usr/bin/
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sudo chmod 700 get_helm.sh
    ./get_helm.sh
    sudo mv ./get_helm.sh /usr/local/bin
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    usermod -aG docker root
    chmod 666 /var/run/docker.sock
    HOME=/home/ec2-user
    echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.caller.account_id}" >> ~/.bashrc
    echo "export AWS_DEFAULT_REGION=ap-northeast-2" >> ~/.bashrc
    source ~/.bashrc
    mkdir ~/image
    mkidr ~/eks
    su - ec2-user -c 'sudo chown ec2-user:ec2-user ~/eks/'
    su - ec2-user -c 'sudo chown ec2-user:ec2-user ~/image/'
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.app.id}/ ~/image --recursive'
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.manifest.id}/ ~/eks --recursive'
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
    docker build -t ${aws_ecr_repository.ecr.repository_url}:latest ~/image/
    docker push ${aws_ecr_repository.ecr.repository_url}:latest
    aws s3 rm s3://${aws_s3_bucket.app.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.app.id} --force
    aws s3 rm s3://${aws_s3_bucket.manifest.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.manifest.id} --force
    public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-a" --query "Subnets[].SubnetId[]" --output text)
    public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-public-b" --query "Subnets[].SubnetId[]" --output text)
    private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-private-a" --query "Subnets[].SubnetId[]" --output text)
    private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=wsi-private-b" --query "Subnets[].SubnetId[]" --output text)
    sed -i "s|public_a|$public_a|g" ~/eks/cluster.yaml
    sed -i "s|public_b|$public_b|g" ~/eks/cluster.yaml
    sed -i "s|private_a|$private_a|g" ~/eks/cluster.yaml
    sed -i "s|private_b|$private_b|g" ~/eks/cluster.yaml
    su - ec2-user -c 'eksctl create cluster -f ~/eks/cluster.yaml'
  EOF
  tags = {
    Name = "wsi-bastion-ec2"
  }
}

resource "aws_security_group" "bastion" {
  name = "wsi-EC2-SG"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "8080"
    to_port = "8080"
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
    from_port = "80"
    to_port = "80"
  }

    tags = {
    Name = "wsi-ec2-SG"
  }
}

resource "aws_iam_role" "bastion" {
  name = "wsi-role-EC2"
  
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
  name = "wsi-profile-ec2"
  role = aws_iam_role.bastion.name
}