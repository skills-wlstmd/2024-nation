data "aws_region" "api_current" {}

resource "aws_iam_role" "dynamodb" {
  name = "dynamodb-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
}

resource "aws_api_gateway_rest_api" "apigw" {
  name = "wsi-api"
}

resource "aws_api_gateway_resource" "apigw_user" {
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  path_part   = "user"
}

resource "aws_api_gateway_resource" "apigw_healthcheck" {
  parent_id   = aws_api_gateway_rest_api.apigw.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  path_part   = "healthz"
}

resource "aws_api_gateway_request_validator" "validate_body" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  name        = "Validate Body"
  validate_request_body = true
  validate_request_parameters = false
}

resource "aws_api_gateway_method" "post" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  authorization = "NONE"
  http_method = "POST"
  request_validator_id = aws_api_gateway_request_validator.validate_body.id

  request_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method" "get" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  authorization = "NONE"
  http_method = "GET"

  request_parameters = {
    "method.request.querystring.name" = true
  }
}

resource "aws_api_gateway_method" "delete" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  authorization = "NONE"
  http_method = "DELETE"

  request_parameters = {
    "method.request.querystring.name" = true
  }
}

resource "aws_api_gateway_method" "healthcheck" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.apigw_healthcheck.id
  authorization = "NONE"
  http_method   = "GET"
}

resource "aws_api_gateway_integration" "post" {
  http_method = aws_api_gateway_method.post.http_method
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.api_current.name}:dynamodb:action/PutItem"
  credentials = aws_iam_role.dynamodb.arn

  request_templates = {
    "application/json" = "${file("./src/post_request.json")}"
  }
}

resource "aws_api_gateway_integration" "get" {
  http_method = aws_api_gateway_method.get.http_method
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.api_current.name}:dynamodb:action/GetItem"
  credentials = aws_iam_role.dynamodb.arn

  request_templates = {
    "application/json" = "${file("./src/get_request.json")}"
  }
}

resource "aws_api_gateway_integration" "delete" {
  http_method = aws_api_gateway_method.delete.http_method
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  integration_http_method = "POST"
  type = "AWS"
  uri  = "arn:aws:apigateway:${data.aws_region.api_current.name}:dynamodb:action/DeleteItem"
  credentials = aws_iam_role.dynamodb.arn

  request_templates = {
    "application/json" = "${file("./src/delete_request.json")}"
  }
}

resource "aws_api_gateway_integration" "healthcheck" {
  rest_api_id          = aws_api_gateway_rest_api.apigw.id
  resource_id          = aws_api_gateway_resource.apigw_healthcheck.id
  http_method          = aws_api_gateway_method.healthcheck.http_method
  type                 = "MOCK"

  request_templates = {
    "application/json" = "${file("./src/healthcheck_request.json")}"
  }
}

resource "aws_api_gateway_method_response" "post" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "delete" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_method_response" "healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_healthcheck.id
  http_method = aws_api_gateway_method.healthcheck.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "post" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./src/post_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.post]
}

resource "aws_api_gateway_integration_response" "get" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./src/get_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.get]
}

resource "aws_api_gateway_integration_response" "delete" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_user.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./src/delete_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.delete]
}

resource "aws_api_gateway_integration_response" "healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_resource.apigw_healthcheck.id
  http_method = aws_api_gateway_method.healthcheck.http_method
  status_code = 200

  response_templates = {
    "application/json" = "${file("./src/healthcheck_response.json")}"
  }

  depends_on = [aws_api_gateway_integration.healthcheck]
}

resource "aws_api_gateway_deployment" "apigw" {
  depends_on = [
    aws_api_gateway_integration.post,
    aws_api_gateway_integration.get,
    aws_api_gateway_integration.delete
  ]
  
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name = "v1"
}
