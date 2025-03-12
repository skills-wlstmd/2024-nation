data "aws_ssm_parameter" "latest_ami_vpc1" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "vpc1-bastion-1" {
  ami = data.aws_ssm_parameter.latest_ami_vpc1.value
  subnet_id = aws_subnet.private_a-1.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.vpc1.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.ssm-bastion.name
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    systemctl restart amazon-ssm-agent.service
    systemctl enable --now amazon-ssm-agent
  EOF
  tags = {
    Name = "gwangju-VPC1-Instance"
  }
  depends_on = [ aws_vpc_endpoint.ec2-1,aws_vpc_endpoint.ec2-message-1,aws_vpc_endpoint.ssm-1,aws_vpc_endpoint.ssm-message-1,aws_vpc_endpoint_subnet_association.sub-a-1,aws_vpc_endpoint_subnet_association.sub-b-1,aws_vpc_endpoint_subnet_association.sub-a-message-1,aws_vpc_endpoint_subnet_association.sub-b-message-1,aws_vpc_endpoint_subnet_association.sub-a-ec2-1,aws_vpc_endpoint_subnet_association.sub-b-ec2-1,aws_vpc_endpoint_subnet_association.sub-a-ec2-message-1,aws_vpc_endpoint_subnet_association.sub-b-ec2-message-1 ]
}