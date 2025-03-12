data "aws_ssm_parameter" "latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "script" {
  ami = data.aws_ssm_parameter.latest_ami.value
  subnet_id = aws_subnet.public_a.id
  instance_type = "t3.micro"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.script.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.app-script.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y jq curl --allowerasing
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    aws configure set default.region ap-northeast-2
    sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
    systemctl restart sshd
    echo "Skill53##" | passwd --stdin ec2-user
    echo "Skill53##" | passwd --stdin root
    yum install -y lynx
    yum install -y python3-pip
    mkdir /home/ec2-user/boto3  
    mkdir /home/ec2-user/flask
    pip download boto3==1.34.143 -d /home/ec2-user/boto3
    pip download flask==3.0.3 -d /home/ec2-user/flask
    aws configure set default.region ap-northeast-2
    yum install -y sshpass
    sshpass -p 'Skill53##' ssh -o StrictHostKeyChecking=no ec2-user@${aws_instance.private-ec2-1.private_ip} 'exit'
    sshpass -p 'Skill53##' scp -o StrictHostKeyChecking=no -r /home/ec2-user/flask ec2-user@${aws_instance.private-ec2-1.private_ip}:/home/ec2-user
    sshpass -p 'Skill53##' scp -o StrictHostKeyChecking=no -r /home/ec2-user/boto3 ec2-user@${aws_instance.private-ec2-1.private_ip}:/home/ec2-user
    sshpass -p 'Skill53##' ssh -o StrictHostKeyChecking=no ec2-user@${aws_instance.private-ec2-1.private_ip} pip install /home/ec2-user/flask/*
    sshpass -p 'Skill53##' ssh -o StrictHostKeyChecking=no ec2-user@${aws_instance.private-ec2-1.private_ip} pip install /home/ec2-user/boto3/*
    sshpass -p 'Skill53##' ssh -o StrictHostKeyChecking=no ec2-user@${aws_instance.private-ec2-1.private_ip} aws configure set default.region ap-northeast-2
    sshpass -p 'Skill53##' ssh -o StrictHostKeyChecking=no ec2-user@${aws_instance.private-ec2-1.private_ip} "nohup python3 /home/ec2-user/app.py > /dev/null 2>&1 &"
  EOF
  tags = {
    Name = "gm-scripts"
  }
  
  depends_on = [
    aws_instance.private-ec2-1
  ]
}

resource "aws_security_group" "script" {
  name = "gm-scripts-sg"
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
  egress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }
    tags = {
    Name = "gm-scripts-sg"
  }
}

resource "aws_iam_role" "app-script" {
  name = "gm-script-role"
  
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

resource "aws_iam_instance_profile" "app-script" {
  name = "gm-profile-script"
  role = aws_iam_role.app-script.name
}