import boto3
import time
import json
import re

athena = boto3.client('athena')
s3 = boto3.client('s3')
cloudwatch = boto3.client('cloudwatch')

# Setting
DB_NAME = "apdev"
DB_TABLE_NAME = "cloudfront_standard_logs"
S3_OUTPUT = "s3://apdev-resource-bucket/result"

# Employee POST Query Format
EMPLOYEE_POST_ALL_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'POST'"
EMPLOYEE_POST_SUCCESS_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'POST' AND sc_status IN (201, 200)"
EMPLOYEE_POST_SUCCESS_REQUEST_TIME = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'POST' AND sc_status IN (201, 200) AND time_taken <= 0.2"

# Employee GET Query Format
EMPLOYEE_GET_ALL_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'GET'"
EMPLOYEE_GET_SUCCESS_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'GET' AND sc_status IN (201, 200)"
EMPLOYEE_GET_SUCCESS_REQUEST_TIME = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/employee' AND cs_method = 'GET' AND sc_status IN (201, 200) AND time_taken <= 0.2"

# Token POST Query Format
TOKEN_POST_ALL_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/token' AND cs_method = 'POST'"
TOKEN_POST_SUCCESS_REQUEST = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/token' AND cs_method = 'POST' AND sc_status = 201"
TOKEN_POST_SUCCESS_REQUEST_TIME = f"SELECT COUNT(*) AS COUNT FROM {DB_NAME}.{DB_TABLE_NAME} WHERE cs_uri_stem = '/v1/token' AND cs_method = 'POST' AND sc_status = 201 AND time_taken <= 0.2"

def lambda_handler(event, context):
    ALL_REQUEST = [EMPLOYEE_POST_ALL_REQUEST, EMPLOYEE_GET_ALL_REQUEST, TOKEN_POST_ALL_REQUEST]
    SUCCESS_REQUEST = [EMPLOYEE_POST_SUCCESS_REQUEST, EMPLOYEE_GET_SUCCESS_REQUEST, TOKEN_POST_SUCCESS_REQUEST]
    REQUEST_TIME = [EMPLOYEE_POST_SUCCESS_REQUEST_TIME, EMPLOYEE_GET_SUCCESS_REQUEST_TIME, TOKEN_POST_SUCCESS_REQUEST_TIME]
    
    NAMESPACES = {
        "employee_post": "employee-post",
        "employee_get": "employee-get",
        "token_post": "token-post"
    }
    
    for i in range(len(ALL_REQUEST)):
        all_request = ALL_REQUEST[i]
        success_request = SUCCESS_REQUEST[i]
        time_request = REQUEST_TIME[i]

        # Run Athena queries and get results
        all_result, success_result, time_result = athena_query(all_request, success_request, time_request)
        all_count = parse_count(all_result)
        success_count = parse_count(success_result)
        time_count = parse_count(time_result)
        
        # Calculate availability and response time counts
        availability_count, response_time_count = request_calculation(all_count, success_count, time_count)
        
        # Determine the namespace based on the request type
        namespace = list(NAMESPACES.values())[i]
        
        # Send metrics to CloudWatch
        send_metric_to_cloudwatch(namespace, 'AvailabilityCount', availability_count)
        send_metric_to_cloudwatch(namespace, 'ResponseTimeCount', response_time_count)

def athena_query(all_query, success_query, time_query):
    all_execution_id = start_query(all_query)
    success_execution_id = start_query(success_query)
    time_execution_id = start_query(time_query)

    all_s3_path = wait_for_query(all_execution_id)
    success_s3_path = wait_for_query(success_execution_id)
    time_s3_path = wait_for_query(time_execution_id)

    all_result, success_result, time_result = s3_download_result(all_s3_path, success_s3_path, time_s3_path)
    
    return all_result, success_result, time_result

def start_query(query):
    response = athena.start_query_execution(
        QueryString=query,
        QueryExecutionContext={'Database': DB_NAME},
        ResultConfiguration={'OutputLocation': S3_OUTPUT}
    )
    return response['QueryExecutionId']

def wait_for_query(execution_id):
    while True:
        result = athena.get_query_execution(QueryExecutionId=execution_id)
        state = result['QueryExecution']['Status']['State']
        if state == 'SUCCEEDED':
            return result['QueryExecution']['ResultConfiguration']['OutputLocation']
        elif state in ['FAILED', 'CANCELLED']:
            raise Exception(f"Query {execution_id} failed or was cancelled")
        time.sleep(2)  # Wait before retrying

def s3_download_result(all_path, success_path, time_path):
    results = []
    for s3_path in [all_path, success_path, time_path]:
        s3_bucket_name = s3_path.split("/")[2]
        s3_key = "/".join(s3_path.split("/")[3:])
        local_file_path = f"/tmp/{s3_key.split('/')[-1]}"
        
        try:
            s3.download_file(s3_bucket_name, s3_key, local_file_path)
            with open(local_file_path, 'r') as file:
                content = file.read()
                results.append(content)
        except s3.exceptions.NoSuchKey:
            raise Exception(f"File not found: {s3_path}")

    return results

def parse_count(content):
    match = re.search(r'"(\d+)"', content)
    if match:
        return int(match.group(1))
    else:
        raise ValueError("Count not found in the content")

def request_calculation(all_count, success_count, time_count):
    if all_count == 0:
        availability_count = 0
        response_time_count = 0
    else:
        availability_count = (success_count / all_count) * 100
        response_time_count = (time_count / all_count) * 100
        
        availability_count = round(availability_count, 2)
        response_time_count = round(response_time_count, 2)
        
    return availability_count, response_time_count

def send_metric_to_cloudwatch(namespace, metric_name, value):
    cloudwatch.put_metric_data(
        Namespace=namespace,
        MetricData=[
            {
                'MetricName': metric_name,
                'Value': value,
                'Unit': 'Percent'
            }
        ]
    )
