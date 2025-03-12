resource "tls_private_key" "gwangju-cicd-rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "gwangju-cicd-keypair" {
  key_name = "gwangju"
  public_key = tls_private_key.gwangju-cicd-rsa.public_key_openssh
}

resource "local_file" "gwangju-cicd-keypair" {
  content = tls_private_key.gwangju-cicd-rsa.private_key_pem
  filename = "./gwangju.pem"
}