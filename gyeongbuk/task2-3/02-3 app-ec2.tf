data "aws_ssm_parameter" "latest_ami_app" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64"
}

resource "aws_instance" "app" {
  ami = data.aws_ssm_parameter.latest_ami_app.value
  subnet_id = aws_subnet.private_a.id
  instance_type = "t3.small"
  key_name = aws_key_pair.keypair.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  associate_public_ip_address = false
  iam_instance_profile = aws_iam_instance_profile.app.name
  user_data = "${file("./src/userdata.sh")}"
  tags = {
    Name = "wsi-app"
  }
}