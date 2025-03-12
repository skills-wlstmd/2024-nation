data "aws_ssm_parameter" "gwangju-cicd-latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "bastion" {
  ami = data.aws_ssm_parameter.gwangju-cicd-latest_ami.value
  subnet_id = aws_subnet.gwangju-cicd-public_a.id
  instance_type = "t3.small"
  key_name = aws_key_pair.gwangju-cicd-keypair.key_name
  vpc_security_group_ids = [aws_security_group.gwangju-cicd-bastion.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.gwangju-cicd-bastion.name
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
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm -rf argocd-linux-amd64
    yum install -y git
    HOME=/home/ec2-user
    echo "export AWS_ACCOUNT_ID=${data.aws_caller_identity.caller.account_id}" >> ~/.bashrc
    echo "export AWS_DEFAULT_REGION=ap-northeast-2" >> ~/.bashrc
    source ~/.bashrc
    mkdir ~/gwangju-application-repo
    mkidr ~/eks
    sudo chown ec2-user:ec2-user ~/gwangju-application-repo
    sudo chown ec2-user:ec2-user ~/eks
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.gwangju-cicd-app.id}/ ~/gwangju-application-repo --recursive'
    su - ec2-user -c 'aws s3 cp s3://${aws_s3_bucket.gwangju-cicd-manifest.id}/ ~/eks --recursive'
    su - ec2-user -c 'git config --global credential.helper "!aws codecommit credential-helper $@"'
    su - ec2-user -c 'git config --global credential.UseHttpPath true'
    su - ec2-user -c 'sed -i "s|ACCOUNT_ID|${data.aws_caller_identity.caller.account_id}|g" ~/gwangju-application-repo/deployment.yaml'
    su - ec2-user -c 'cd ~/gwangju-application-repo && git init && git add .'
    su - ec2-user -c 'cd ~/gwangju-application-repo && git commit -m "day2"'
    su - ec2-user -c 'cd ~/gwangju-application-repo && git remote add origin https://wlstmd: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@github.com/wlstmd/gwangju-application-repo'
    su - ec2-user -c 'cd ~/gwangju-application-repo && git push origin master'
    aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
    docker build -t ${aws_ecr_repository.gwangju-cicd-ecr.repository_url}:latest ~/gwangju-application-repo
    docker push ${aws_ecr_repository.gwangju-cicd-ecr.repository_url}:latest
    aws s3 rm s3://${aws_s3_bucket.gwangju-cicd-app.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.gwangju-cicd-app.id} --force
    aws s3 rm s3://${aws_s3_bucket.gwangju-cicd-manifest.id} --recursive
    aws s3 rb s3://${aws_s3_bucket.gwangju-cicd-manifest.id} --force
    public_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=gwangju-public-a" --query "Subnets[].SubnetId[]" --output text)
    public_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=gwangju-public-b" --query "Subnets[].SubnetId[]" --output text)
    private_a=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=gwangju-private-a" --query "Subnets[].SubnetId[]" --output text)
    private_b=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=gwangju-private-b" --query "Subnets[].SubnetId[]" --output text)
    sed -i "s|public_a|$public_a|g" ~/eks/cluster.yaml
    sed -i "s|public_b|$public_b|g" ~/eks/cluster.yaml
    sed -i "s|private_a|$private_a|g" ~/eks/cluster.yaml
    sed -i "s|private_b|$private_b|g" ~/eks/cluster.yaml
    su - ec2-user -c 'eksctl create cluster -f ~/eks/cluster.yaml'
  EOF
  tags = {
    Name = "gwangju-bastion-ec2"
  }
}

resource "aws_security_group" "gwangju-cicd-bastion" {
  name = "gwangju-ec2-SG"
  vpc_id = aws_vpc.gwangju-cicd-main.id

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
    Name = "gwangju-ec2-SG"
  }
}

resource "aws_iam_role" "gwangju-cicd-bastion" {
  name = "gwangju-role-bastion"
  
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

resource "aws_iam_instance_profile" "gwangju-cicd-bastion" {
  name = "gwangju-profile-bastion"
  role = aws_iam_role.gwangju-cicd-bastion.name
}