import json
import boto3
import datetime

config = boto3.client('config')
logs = boto3.client('logs')
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    now = datetime.datetime.now()
    kst_now = now + datetime.timedelta(hours=9)
    time = kst_now.strftime("%Y-%m-%d %H:%M:%S")
    
    invoking_event = json.loads(event['invokingEvent'])
    
    inbound_port_list = []
    outbound_port_list = []
    deleted_ports = []
    
    if 'ipPermissions' in invoking_event['configurationItem']['configuration']:
        for item in invoking_event['configurationItem']['configuration']['ipPermissions']:
            if isinstance(item['fromPort'], int):
                inbound_port_list.append(item['fromPort'])
    
    if 'ipPermissionsEgress' in invoking_event['configurationItem']['configuration']:
        for item in invoking_event['configurationItem']['configuration']['ipPermissionsEgress']:
            if isinstance(item['fromPort'], int):
                outbound_port_list.append(item['fromPort'])
    
    security_group_id = invoking_event['configurationItem']['configuration']['groupId']
    
    check_port_result, deleted_inbound_ports, deleted_outbound_ports = check_port(inbound_port_list, outbound_port_list)
    instance_id = get_instance_id()

    for port in deleted_inbound_ports:
        log_message = f"{time} Inbound {port} Deleted Port!"
        logging(log_message, instance_id)
        inbound_delete_port(port, security_group_id)
    
    for port in deleted_outbound_ports:
        log_message = f"{time} Outbound {port} Deleted Port!"
        logging(log_message, instance_id)
        outbound_delete_port(port, security_group_id)
    
    compliance_type = 'COMPLIANT' if check_port_result else 'NON_COMPLIANT'
    
    evaluation = {
        'ComplianceResourceType': invoking_event['configurationItem']['resourceType'],
        'ComplianceResourceId': invoking_event['configurationItem']['resourceId'],
        'ComplianceType': compliance_type,
        'OrderingTimestamp': invoking_event['configurationItem']['configurationItemCaptureTime'],
        'Annotation': 'Security Group port check'
    }
    
    result_token = event['resultToken']
    if result_token != 'TESTMODE':
        config.put_evaluations(
            Evaluations=[evaluation],
            ResultToken=result_token
        )

def check_port(inbound_port_list, outbound_port_list):
    allowed_inbound_ports = {22, 80}
    allowed_outbound_ports = {22, 80, 443}

    deleted_inbound_ports = []
    deleted_outbound_ports = []

    for port in inbound_port_list:
        if port not in allowed_inbound_ports:
            deleted_inbound_ports.append(port)
    
    for port in outbound_port_list:
        if port not in allowed_outbound_ports:
            deleted_outbound_ports.append(port)
    
    result = not (deleted_inbound_ports or deleted_outbound_ports)
    
    return result, deleted_inbound_ports, deleted_outbound_ports

def logging(message, instance_id):
    timestamp = int(datetime.datetime.now().timestamp() * 1000)
    LOG_GROUP = "/ec2/deny/port"
    LOG_STREAM = "deny-" + str(instance_id)
    response = logs.put_log_events(
        logGroupName=LOG_GROUP,
        logStreamName=LOG_STREAM,
        logEvents=[
            {
                'timestamp': timestamp,
                'message': message
            }
        ]
    )

def inbound_delete_port(inbound_port, sg_id):
    security_group_id = sg_id
    port = inbound_port
    protocol = 'tcp'

    try:
        response = ec2.revoke_security_group_ingress(
            GroupId=security_group_id,
            IpPermissions=[
                {
                    'IpProtocol': protocol,
                    'FromPort': port,
                    'ToPort': port,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                }
            ]
        )
    except boto3.exceptions.botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.NotFound':
            log_message = f"Security group rule for inbound port {port} not found."
            logging(log_message, sg_id)
        else:
            raise
    
def outbound_delete_port(outbound_port, sg_id):
    security_group_id = sg_id
    port = outbound_port
    protocol = 'tcp'

    try:
        response = ec2.revoke_security_group_egress(
            GroupId=security_group_id,
            IpPermissions=[
                {
                    'IpProtocol': protocol,
                    'FromPort': port,
                    'ToPort': port,
                    'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
                }
            ]
        )
    except boto3.exceptions.botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == 'InvalidPermission.NotFound':
            log_message = f"Security group rule for outbound port {port} not found."
            logging(log_message, sg_id)
        else:
            raise
    
def get_instance_id():
    instances = ec2.describe_instances(
        Filters = [
            {
                'Name': 'tag:Name',
                'Values': ["wsi-app-ec2"]
            }
        ]
    )
    
    instance_id = instances['Reservations'][0]['Instances'][0]['InstanceId']
    
    return instance_id
