data "aws_ssm_parameter" "latest_ami_egress" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "egress-bastion" {
  ami = data.aws_ssm_parameter.latest_ami_egress.value
  subnet_id = aws_subnet.egress-private_b.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.egress.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.egress-bastion.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl enable --now amazon-ssm-agent
  EOF
  tags = {
    Name = "gwangju-EgressVPC-Instance"
  }
}