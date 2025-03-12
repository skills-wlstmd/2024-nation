resource "aws_instance" "private-ec2-1" {
  ami = data.aws_ssm_parameter.latest_ami.value
  subnet_id = aws_subnet.private_a.id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.gm-private-sg.id]
  iam_instance_profile = aws_iam_instance_profile.bastion.name
  user_data = <<-EOF
    #!/bin/bash
    echo "Skill53##" | passwd --stdin ec2-user
    sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
    systemctl restart sshd
    yum update -y
    yum install -y curl jq --allowerasing
    yum install -y python3-pip
    yum install -y zip --allowerasing
    cd /home/ec2-user
    cat <<SOS> app.py
    from flask import Flask, render_template, request
    import boto3
    import logging
    import os

    app = Flask(__name__)

    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    dynamodb = boto3.client('dynamodb')

    @app.route('/', methods=['GET', 'POST'])
    def index():
        if request.method == 'POST':
            try:
                table_name = request.form['table_name']
                s3_bucket = request.form['s3_bucket']
                attribute1_value = request.form['attribute1_value']
                attribute2_value = request.form['attribute2_value']

                response = dynamodb.put_item(
                    TableName=table_name,
                    Item={
                        'PK': {'S': 'partition_key_value'},
                        'SK': {'S': 'sort_key_value'},        
                        'Attribute1': {'S': attribute1_value},
                        'Attribute2': {'S': attribute2_value}
                    }
                )

                logger.info(f"Item added to DynamoDB successfully. Attribute1: {attribute1_value}, Attribute2: {attribute2_value}")

                try:
                    with open('logs.log', 'a') as log_file:
                        log_file.write(f"Item added to DynamoDB successfully. Attribute1: {attribute1_value}, Attribute2: {attribute2_value}\n")

                except Exception as e:
                    logger.error(f"Error writing logs to file: {e}")

                try:
                    file_name = 'logs.log'

                    with open(file_name, 'rb') as data:
                        s3 = boto3.client('s3')
                        s3.upload_fileobj(data, s3_bucket, file_name)

                    logger.info("Logs uploaded to S3 successfully.")

                    os.remove(file_name)

                except Exception as e:
                    logger.error(f"Error uploading logs to S3: {e}")

            except Exception as e:
                logger.error(f"Error adding item to DynamoDB: {e}")
                return "Error adding item to DynamoDB"
        
        return render_template('index.html')

    @app.route('/healthcheck')
    def healthcheck():
        return "OK"

    if __name__ == "__main__":
        app.run(host='0.0.0.0', port=5000, debug=True)
    SOS
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    ln -s /usr/local/bin/aws /usr/bin/
    ln -s /usr/local/bin/aws_completer /usr/bin/
    mkdir /home/ec2-user/templates
    cat <<IND> /home/ec2-user/templates/index.html
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>DynamoDB Items</title>
    </head>
    <body>
        <h1>Add Item to DynamoDB</h1>
        <form action="/" method="post">
            <label for="table_name">Table Name:</label>
            <input type="text" id="table_name" name="table_name"><br><br>
            
            <label for="attribute1_value">Attribute1:</label>
            <input type="text" id="attribute1_value" name="attribute1_value"><br><br>
            
            <label for="attribute2_value">Attribute2:</label>
            <input type="text" id="attribute2_value" name="attribute2_value"><br><br>
            
            <label for="s3_bucket">S3 Bucket Name:</label>
            <input type="text" id="s3_bucket" name="s3_bucket"><br><br>
            
            <input type="submit" value="Submit">
        </form>
    </body>
    </html>
    IND
    yum install -y lynx
  EOF
  tags = {
    Name = "gm-bastion"
  }
}

resource "aws_security_group" "gm-private-sg" {
  name = "gm-bastion-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "22"
    to_port = "22"
  }

  ingress {
    protocol = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
    from_port = "5000"
    to_port = "5000"
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
    Name = "gm-bastion-sg"
  }
}