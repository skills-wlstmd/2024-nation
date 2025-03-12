data "aws_ssm_parameter" "app_latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "test" {
  ami = data.aws_ssm_parameter.app_latest_ami.value
  subnet_id = aws_subnet.public_a.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.test.id]
  associate_public_ip_address = true
  user_data = <<-EOF
  #!/bin/bash
    yum update -y
    yum install -y curl jq --allowerasing
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
  EOF
  tags = {
    Name = "wsi-test"
  }
}