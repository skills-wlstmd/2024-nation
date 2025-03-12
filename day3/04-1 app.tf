# resource "aws_instance" "app1" {
#   ami = data.aws_ssm_parameter.latest_ami.value
#   subnet_id = aws_subnet.app_a.id
#   instance_type = "t3.micro"
#   key_name = aws_key_pair.keypair.key_name
#   vpc_security_group_ids = [aws_security_group.app.id]
#   associate_public_ip_address = false
#   iam_instance_profile = aws_iam_instance_profile.app.name
#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y jq curl wget zip
#     dnf install -y mariadb105
#     curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#     unzip awscliv2.zip
#     sudo ./aws/install
#     ln -s /usr/local/bin/aws /usr/bin/
#     ln -s /usr/local/bin/aws_completer /usr/bin/
#     sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
#     systemctl restart sshd
#     echo 'Skill53##' | passwd --stdin ec2-user
#     echo 'Skill53##' | passwd --stdin root
#     yum install -y docker
#     systemctl enable --now docker
#     usermod -aG docker ec2-user
#     usermod -aG docker root
#     chmod 666 /var/run/docker.sock
#     export SECRET_NAME=$(aws secretsmanager list-secrets --query "SecretList[?Name=='rds-secret'].Name" --output text)
#     export MYSQL_USER=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".username")
#     export MYSQL_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".password")
#     export MYSQL_HOST=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".proxy_host")
#     export MYSQL_PORT=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".proxy_port")
#     export MYSQL_DBNAME=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --query "SecretString" --output text | jq -r ".dbname")
#     aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
#     docker run -d -p 8080:8080 -e MYSQL_USER=$MYSQL_USER -e MYSQL_PASSWORD=$MYSQL_PASSWORD -e MYSQL_HOST=$MYSQL_HOST -e MYSQL_PORT=$MYSQL_PORT -e MYSQL_DBNAME=$MYSQL_DBNAME ${aws_ecr_repository.ecr.repository_url}:employee
#     docker run -d -p 8080:8080 ${aws_ecr_repository.ecr.repository_url}:employee
#   EOF
#   tags = {
#     Name = "apdev-app1"
#   }
#   depends_on = [
#     aws_instance.bastion,
#     aws_db_instance.db,
#     aws_db_proxy.db,
#     aws_db_proxy_target.rds_proxy,
#     aws_secretsmanager_secret.db,
#     aws_secretsmanager_secret_version.db
#   ]
# }

# resource "aws_instance" "app2" {
#   ami = data.aws_ssm_parameter.latest_ami.value
#   subnet_id = aws_subnet.app_b.id
#   instance_type = "t3.micro"
#   key_name = aws_key_pair.keypair.key_name
#   vpc_security_group_ids = [aws_security_group.app.id]
#   associate_public_ip_address = false
#   iam_instance_profile = aws_iam_instance_profile.app.name
#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y jq curl wget zip
#     dnf install -y mariadb105
#     curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
#     unzip awscliv2.zip
#     sudo ./aws/install
#     ln -s /usr/local/bin/aws /usr/bin/
#     ln -s /usr/local/bin/aws_completer /usr/bin/
#     sed -i "s|#PasswordAuthentication no|PasswordAuthentication yes|g" /etc/ssh/sshd_config
#     systemctl restart sshd
#     echo 'Skill53##' | passwd --stdin ec2-user
#     echo 'Skill53##' | passwd --stdin root
#     yum install -y docker
#     systemctl enable --now docker
#     usermod -aG docker ec2-user
#     usermod -aG docker root
#     chmod 666 /var/run/docker.sock
#     aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.caller.account_id}.dkr.ecr.ap-northeast-2.amazonaws.com
#     docker pull ${aws_ecr_repository.ecr.repository_url}:token
#     docker run -d -p 8080:8080 ${aws_ecr_repository.ecr.repository_url}:token
#   EOF
#   tags = {
#     Name = "apdev-app2"
#   }
#   depends_on = [
#     aws_instance.bastion,
#     aws_db_instance.db,
#     aws_db_proxy.db,
#     aws_db_proxy_target.rds_proxy,
#     aws_secretsmanager_secret.db,
#     aws_secretsmanager_secret_version.db
#   ]
# }