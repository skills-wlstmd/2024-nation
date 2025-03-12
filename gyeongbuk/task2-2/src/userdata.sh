#!/bin/bash
yum update -y
yum install -y jq curl wget --allowerasing
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
ln -s /usr/local/bin/aws /usr/bin/
ln -s /usr/local/bin/aws_completer /usr/bin/
sed -i 's|.*PasswordAuthentication.*|PasswordAuthentication yes|g' /etc/ssh/sshd_config
systemctl restart sshd
echo "Skill53##" | passwd --stdin ec2-user
echo "Skill53##" | passwd --stdin root
yum install -y python3-pip
pip3 install flask
cat <<EOF> main.py
from flask import Flask, request, jsonify, make_response
import jwt
import datetime
import base64
import json

app = Flask(__name__)

SECRET_KEY = 'jwtsecret'

@app.route('/v1/token', methods=['GET'])
def get_token():
    payload = {
        'isAdmin': False,
        'exp': datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)
    }
    token = jwt.encode(payload, SECRET_KEY, algorithm='HS256')
    return jsonify({'token': token})

@app.route('/v1/token/verify', methods=['GET'])
def verify_token():
    token = request.headers.get('Authorization')
    if not token:
        return make_response('Token is missing', 403)

    decoded = jwt.decode(token, options={"verify_signature": False})
    isAdmin = decoded.get('isAdmin', False)
    if isAdmin:
        return 'You are admin!'
    else:
        return 'You are not permitted'

@app.route('/v1/token/none', methods=['GET'])
def get_none_alg_token():
    payload = {
        'isAdmin': True,
        'exp': (datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(minutes=5)).timestamp()
    }

    header = {
        'alg': 'none',
        'typ': 'JWT'
    }

    encoded_header = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip("=")
    encoded_payload = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip("=")

    token = f"{encoded_header}.{encoded_payload}."
    return jsonify({'token': token})

@app.route('/healthcheck', methods=['GET'])
def health_check():
    return make_response('ok', 200)

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
EOF
echo "flask==3.0.3" >> ./requirements.txt
echo "pyjwt==2.8.0" >> ./requirements.txt
pip3 install --no-cache-dir -r ./requirements.txt
sudo FLASK_APP=main.py nohup flask run --host=0.0.0.0 --port=80 &
