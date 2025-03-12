import boto3
import gzip
import json
from base64 import b64decode

def lambda_handler(event, context):
    # print(event)
    client = boto3.client('iam')
    message = event['awslogs']['data']
    compressed_payload = b64decode(message)
    uncompressed_payload = gzip.decompress(compressed_payload)
    payload = json.loads(uncompressed_payload)
    log_msg = payload["logEvents"][0]["message"]
    log_msg_json = json.loads(log_msg)
    role_name = log_msg_json["requestParameters"]["roleName"]
    policy_arn = log_msg_json["requestParameters"]["policyArn"]
    User_arn = log_msg_json["userIdentity"]["arn"]
    account_id = boto3.client("sts").get_caller_identity()["Account"]
    # print(User_arn)
    # print(policy_arn)
    if "wsc2024-instance-role" == role_name and f"arn:aws:iam::{account_id}:user/Employee" == User_arn:
        response = client.detach_role_policy(
            RoleName=role_name,
            PolicyArn=policy_arn
        )
        print("good")
        return {"msg": f"successfully detached policies! {policy_arn}"}
    else:
        return {"msg": "no search policy"}