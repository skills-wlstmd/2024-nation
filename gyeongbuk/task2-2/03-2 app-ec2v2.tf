data "aws_ssm_parameter" "latest_ami_app_2" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64"
}

resource "aws_instance" "app_2" {
  ami = data.aws_ssm_parameter.latest_ami_app_2.value
  subnet_id = aws_subnet.private_b.id
  instance_type = "t4g.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.app.name
  user_data = "${file("./src/userdata.sh")}"
  tags = {
    Name = "wsi-token2-ec2"
  }
}