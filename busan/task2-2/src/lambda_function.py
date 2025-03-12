import json
import boto3
import base64
import time
import gzip
import io

logs = boto3.client('logs')

def get_user_name(data):
    data = data['logEvents'][0]['message']
    data = json.loads(data)
    user_name = data['userIdentity']['userName']
    return user_name
    
def send_log(user_name):
    LOG_GROUP='wsi-project-login'
    LOG_STREAM='wsi-project-login-stream'
    
    timestamp = int(round(time.time() * 1000))
    
    response = logs.put_log_events(
        logGroupName=LOG_GROUP,
        logStreamName=LOG_STREAM,
        logEvents=[
            {
                'timestamp': timestamp,
                'message': f'{{ USER: "{user_name} has logged in!" }}'
            }
        ]
    )
    return response

def lambda_handler(event, context):
    data = event['awslogs']['data']
    data = base64.b64decode(data)
    with gzip.GzipFile(fileobj=io.BytesIO(data)) as f:
        decord_data = f.read()
        
    data = json.loads(decord_data.decode('utf-8'))

    user_name = get_user_name(data)
    logging = send_log(user_name)
    return logging