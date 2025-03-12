import json
import boto3
import botocore
from datetime import datetime

# Constants and client initialization
APPLICABLE_RESOURCES = ["AWS::EC2::SecurityGroup"]
ec2_client = boto3.client('ec2')
config_client = boto3.client('config')

class DateTimeEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super().default(obj)

# Required permissions
REQUIRED_PERMISSIONS = [
    {
        "IpProtocol": "tcp",
        "FromPort": 22,
        "ToPort": 22,
        "IpRanges": [{"CidrIp": "121.159.179.130/32"}]
    },
    {
        "IpProtocol": "tcp",
        "FromPort": 80,
        "ToPort": 80,
        "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
    },
    {
        "IpProtocol": "tcp",
        "FromPort": 3306,
        "ToPort": 3306,
        "IpRanges": [{"CidrIp": "0.0.0.0/0"}]
    }
]

EGRESS_REQUIRED_PERMISSIONS = [
    {
        "IpProtocol": "-1",
        "IpRanges": [{"CidrIp": "10.0.0.0/16"}]
    }
]

def normalize_parameters(rule_parameters):
    for key, value in rule_parameters.items():
        normalized_key = key.lower()
        normalized_value = value.lower() == 'true'
        rule_parameters[normalized_key] = normalized_value
    return rule_parameters

def set_security_group_permissions(group_id, debug_enabled):
    try:
        response = ec2_client.describe_security_groups(GroupIds=[group_id])
    except botocore.exceptions.ClientError as e:
        return {"compliance_type": "NON_COMPLIANT", "annotation": "describe_security_groups failure on group " + group_id}
    
    if debug_enabled:
        print("Security group definition: ", json.dumps(response, indent=2))
    
    ip_permissions = response["SecurityGroups"][0]["IpPermissions"]
    ip_permissions_egress = response["SecurityGroups"][0]["IpPermissionsEgress"]

    # Revoke all existing permissions
    if ip_permissions:
        if debug_enabled:
            print("Revoking ingress permissions for ", group_id, json.dumps(ip_permissions, indent=2))
        try:
            ec2_client.revoke_security_group_ingress(GroupId=group_id, IpPermissions=ip_permissions)
        except botocore.exceptions.ClientError as e:
            return {"compliance_type": "NON_COMPLIANT", "annotation": "revoke_security_group_ingress failure on group " + group_id}
    
    if ip_permissions_egress:
        if debug_enabled:
            print("Revoking egress permissions for ", group_id, json.dumps(ip_permissions_egress, indent=2))
        try:
            ec2_client.revoke_security_group_egress(GroupId=group_id, IpPermissions=ip_permissions_egress)
        except botocore.exceptions.ClientError as e:
            return {"compliance_type": "NON_COMPLIANT", "annotation": "revoke_security_group_egress failure on group " + group_id}

    # Add required permissions
    try:
        if REQUIRED_PERMISSIONS:
            ec2_client.authorize_security_group_ingress(GroupId=group_id, IpPermissions=REQUIRED_PERMISSIONS)
        if EGRESS_REQUIRED_PERMISSIONS:
            ec2_client.authorize_security_group_egress(GroupId=group_id, IpPermissions=EGRESS_REQUIRED_PERMISSIONS)
    except botocore.exceptions.ClientError as e:
        return {"compliance_type": "NON_COMPLIANT", "annotation": "authorize_security_group failure on group " + group_id}

    return {"compliance_type": "COMPLIANT", "annotation": "Permissions are correctly set."}

def lambda_handler(event, context):
    invoking_event = json.loads(event['invokingEvent'])
    configuration_item = invoking_event["configurationItem"]
    rule_parameters = event.get("ruleParameters", "{}")
    rule_parameters = normalize_parameters(json.loads(rule_parameters))
    debug_enabled = rule_parameters.get("debug", True)

    if debug_enabled:
        print("Received event: " + json.dumps(event, indent=2))

    # Fetch security groups of instances with tag 'Name: wsi-test'
    response = ec2_client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': ['wsi-test']}])
    ec2_describe = json.dumps(response, cls=DateTimeEncoder)
    response_dict = json.loads(ec2_describe)
    security_groups = []
    for reservation in response_dict['Reservations']:
        for instance in reservation['Instances']:
            security_groups.extend(instance['SecurityGroups'])
    group_ids = [sg["GroupId"] for sg in security_groups]
    
    # Evaluate compliance for each security group associated with 'wsi-test' instances
    evaluation_results = []
    for group_id in group_ids:
        evaluation_result = set_security_group_permissions(group_id, debug_enabled)
        evaluation_results.append(evaluation_result)

    # Determine overall compliance
    overall_compliance_type = "COMPLIANT"
    overall_annotation = "All security groups are compliant."
    for result in evaluation_results:
        if result["compliance_type"] == "NON_COMPLIANT":
            overall_compliance_type = "NON_COMPLIANT"
            overall_annotation = result["annotation"]
            break

    config_client.put_evaluations(
        Evaluations=[
            {
                'ComplianceResourceType': invoking_event['configurationItem']['resourceType'],
                'ComplianceResourceId': invoking_event['configurationItem']['resourceId'],
                'ComplianceType': overall_compliance_type,
                "Annotation": overall_annotation,
                'OrderingTimestamp': invoking_event['configurationItem']['configurationItemCaptureTime']
            },
        ],
        ResultToken=event['resultToken']
    )
    
    return {
        "compliance_type": overall_compliance_type,
        "annotation": overall_annotation
    }