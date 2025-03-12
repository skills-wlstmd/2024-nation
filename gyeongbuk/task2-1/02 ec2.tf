data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "wsi"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./wsi.pem"
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  associate_with_private_ip = aws_instance.bastion.private_ip
}

data "aws_caller_identity" "current" {}

locals {
  aws_region = "ap-northeast-2"
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
    yum install -y jq curl wget git --allowerasing
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    yum install -y docker
    systemctl enable --now docker
    usermod -aG docker ec2-user
    usermod -aG docker root
    chmod 666 /var/run/docker.sock
    sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
    systemctl restart sshd
    echo 'Skill53##' | passwd --stdin ec2-user
    echo 'Skill53##' | passwd --stdin root
    yum install -y git
    echo "export AWS_DEFAULT_REGION=ap-northeast-2" >> ~/.bashrc
    source ~/.bashrc
    mkdir ~/wsi-commit
    sudo chown ec2-user:ec2-user ~/wsi-commit
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.app.id}/ ~/wsi-commit --recursive'
    su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
    su - ec2-user -c 'git config --global credential.UseHttpPath true'
    su - ec2-user -c 'cd ~/wsi-commit && git init && git add .'
    su - ec2-user -c 'cd ~/wsi-commit && git commit -m "day2"'
    su - ec2-user -c 'cd ~/wsi-commit && git branch main'
    su - ec2-user -c 'cd ~/wsi-commit && git checkout main'
    su - ec2-user -c 'cd ~/wsi-commit && git branch -d master'
    su - ec2-user -c 'cd ~/wsi-commit && git remote add origin https://wlstmd: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@github.com/wlstmd/wsi-commit'
    su - ec2-user -c 'cd ~/wsi-commit && git push origin main'
    aws s3 rm s3://${aws_s3_bucket.app.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.app.id} --force
  EOF
  
  tags = {
    Name = "wsi-bastion"
  }
}

resource "aws_security_group" "bastion" {
  name = "wsi-bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
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
    Name = "wsi-bastion-sg"
  }
}

resource "random_string" "random" {
  length           = 5
  upper            = false
  lower            = false
  numeric          = true
  special          = false
}

resource "aws_iam_role" "bastion" {
  name = "wsi-role-bastion"
  
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
  name = "wsi-profile-bastion-${random_string.random.result}"
  role = aws_iam_role.bastion.name
}