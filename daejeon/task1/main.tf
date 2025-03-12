module "seoul" {
    source = "./modules"
    create_region = "ap-northeast-2"
    destination_region = "us-east-1"   
    key_name = aws_key_pair.keypair.key_name
    ecr_url = aws_ecr_repository.ecr.repository_url
    providers = {
      aws = aws.seoul
    }
}

module "usa" {
    source = "./modules"
    create_region = "us-east-1"
    destination_region = "ap-northeast-2"
    key_name = aws_key_pair.usa_keypair.key_name
    ecr_url = aws_ecr_repository.ecr.repository_url
    providers = {
      aws = aws.usa
    }
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "aws_key_pair" "keypair" {
  key_name = "hrdkorea"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "aws_key_pair" "usa_keypair" {
  provider = aws.usa
  key_name = "hrdkorea"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "keypair" {
  content = tls_private_key.rsa.private_key_pem
  filename = "./hrdkorea.pem"
}

# DynamoDB
resource "aws_dynamodb_global_table" "myTable" {

  depends_on = [
    aws_dynamodb_table.ap_northeast_2,
    aws_dynamodb_table.us_east_1,
  ]

  provider = aws.seoul
  name     = "order"

  replica {
    region_name = "ap-northeast-2"
  }

  replica {
    region_name = "us-east-1"
  }
}


resource "aws_dynamodb_table" "us_east_1" {
  provider = aws.usa
  billing_mode   = "PAY_PER_REQUEST"
  hash_key         = "id"
  name             = "order"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table" "ap_northeast_2" {
  provider = aws.seoul
  billing_mode   = "PAY_PER_REQUEST"
  hash_key         = "id"
  name             = "order"
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "random_string" "bucket_random" {
  length           = 4
  upper   = false
  lower   = false
  numeric  = true
  special = false
}
resource "aws_s3_bucket" "source" {
  provider = aws.seoul
  bucket   = "hrdkorea-static-${random_string.bucket_random.result}"
}

resource "aws_s3_object" "static" {
  bucket = aws_s3_bucket.source.id
  key    = "static/index.html"
  source = "./src/index.html"
  etag   = filemd5("./src/index.html")
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "cdn-oac-bucket-policy" {
  bucket = aws_s3_bucket.source.id
  policy = data.aws_iam_policy_document.static_s3_policy.json
}

data "aws_iam_policy_document" "static_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.source.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cf_dist.arn]
    }
  }
}

resource "aws_s3_bucket_website_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_versioning" "source" {
  provider = aws.seoul
  bucket   = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

### RDS
resource "aws_rds_global_cluster" "example" {
  global_cluster_identifier = "hrdkorea-rds"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.05.2"
  database_name             = "hrdkorea-global"
  lifecycle {
    ignore_changes = [
      "global_cluster_identifier",
      "engine",
      "engine_version"
    ]
  }
}

resource "aws_rds_cluster" "primary" {
  provider                  = aws.seoul
  engine                    = aws_rds_global_cluster.example.engine
  engine_version            = aws_rds_global_cluster.example.engine_version
  cluster_identifier        = "hrdkorea-rds-instance"
  master_username           = "hrdkorea_user"
  master_password           = "Skill53##"
  db_cluster_parameter_group_name = module.seoul.cluster_parameter_group
  port = 3409
  database_name             = "hrdkorea"
  global_cluster_identifier = aws_rds_global_cluster.example.id
  db_subnet_group_name      = module.seoul.subnet_group
  vpc_security_group_ids    = [module.seoul.security_group]
  skip_final_snapshot = true
  lifecycle {
    ignore_changes = [
      "db_subnet_group_name",
      "cluster_identifier",
      "db_cluster_parameter_group_name"
    ]
  }
}

resource "aws_rds_cluster_instance" "primary" {
  provider             = aws.seoul
  engine               = aws_rds_global_cluster.example.engine
  engine_version       = aws_rds_global_cluster.example.engine_version
  db_parameter_group_name = module.seoul.paramter_group
  identifier           = "hrdkorea-rds-instance"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = "db.r5.large"
  db_subnet_group_name = module.seoul.subnet_group
  lifecycle {
    ignore_changes = [
      "db_parameter_group_name",
      "cluster_identifier",
      "db_subnet_group_name"
    ]
  }
}

resource "aws_rds_cluster" "secondary" {
  provider                  = aws.usa
  engine                    = aws_rds_global_cluster.example.engine
  engine_version            = aws_rds_global_cluster.example.engine_version
  cluster_identifier        = "hrdkorea-rds-instance-us"
  global_cluster_identifier = aws_rds_global_cluster.example.id
  db_cluster_parameter_group_name = module.seoul.cluster_parameter_group
  port = 3409
  db_subnet_group_name      = module.usa.subnet_group
  vpc_security_group_ids    = [module.usa.security_group]
  skip_final_snapshot = true
  enable_global_write_forwarding = true
  depends_on = [
    aws_rds_cluster_instance.primary
  ]
  lifecycle {
    ignore_changes = [
      "global_cluster_identifier",
      "db_cluster_parameter_group_name",
      "db_cluster_parameter_group_name"
    ]
  }
}

resource "aws_rds_cluster_instance" "secondary" {
  provider             = aws.usa
  engine               = aws_rds_global_cluster.example.engine
  engine_version       = aws_rds_global_cluster.example.engine_version
  db_parameter_group_name = module.usa.paramter_group
  identifier           = "hrdkorea-rds-instance-us"
  cluster_identifier   = aws_rds_cluster.secondary.id
  instance_class       = "db.r5.large"
  db_subnet_group_name = module.usa.subnet_group
  lifecycle {
    ignore_changes = [
      "db_parameter_group_name",
      "cluster_identifier",
      "db_subnet_group_name"
    ]
  }
}

resource "aws_secretsmanager_secret" "seoul" {
  provider                  = aws.seoul

  name = "mysql/secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret" "usa" {
  provider                  = aws.usa

  name = "mysql/secret"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "seoul" {
  provider                  = aws.seoul

  secret_id     = aws_secretsmanager_secret.seoul.id
  secret_string = jsonencode({
    "username"            = aws_rds_cluster.primary.master_username
    "password"            = aws_rds_cluster.primary.master_password
    "engine"              = aws_rds_cluster.primary.engine
    "host"                = aws_rds_cluster.primary.endpoint
    "port"                = aws_rds_cluster.primary.port
    "dbClusterIdentifier" = aws_rds_cluster.primary.cluster_identifier
    "dbname"              = aws_rds_cluster.primary.database_name
    "aws_region"          = "ap-northeast-2"
  })
}

resource "aws_secretsmanager_secret_version" "usa" {
  provider                  = aws.usa

  secret_id     = aws_secretsmanager_secret.usa.id
  secret_string = jsonencode({
    "username"            = aws_rds_cluster.secondary.master_username
    "password"            = aws_rds_cluster.primary.master_password
    "engine"              = aws_rds_cluster.secondary.engine
    "host"                = aws_rds_cluster.secondary.endpoint
    "port"                = aws_rds_cluster.secondary.port
    "dbClusterIdentifier" = aws_rds_cluster.secondary.cluster_identifier
    "dbname"              = aws_rds_cluster.secondary.database_name
    "aws_region"          = "us-east-1"
  })
}


### Cloudfront
##S3_oac
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "s3_oac_${random_string.bucket_random.result}"
  description                       = "S3 OAC Policy"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  seoul_s3_origin_id = "seoul_S3Origin"
  alb_origin_id = "alb-origin"
}

data "aws_s3_bucket" "seoul_bucket" {
  bucket = aws_s3_bucket.source.bucket
  provider = aws.seoul
}

resource "aws_cloudfront_distribution" "cf_dist" {
  origin {
    domain_name              = data.aws_s3_bucket.seoul_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    origin_id                = local.seoul_s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "CloudFront For S3, ALB"
  default_root_object = "static/index.html"

  default_cache_behavior {
    cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id = local.seoul_s3_origin_id

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    compress = true
    viewer_protocol_policy = "https-only"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Name = "hrdkorea-cdn"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
output "cloudfront_arn" {
  value = aws_cloudfront_distribution.cf_dist.arn
}

locals {
  code_path = "./src"
}

# Assume Role Policy Document
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Inline Policy Document
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"
    actions   = [
      "s3:GetObject",
      "logs:CreateLogStream",
      "iam:CreateServiceLinkedRole",
      "logs:DescribeLogStreams",
      "lambda:GetFunction",
      "cloudfront:UpdateDistribution",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "lambda:EnableReplication",
      "ec2:*",
      "elasticloadbalancing:DescribeLoadBalancers"
    ]
    resources = ["*"]
  }
}

# IAM Role
resource "aws_iam_role" "lambda" {
  name               = "Lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# IAM Role Policy
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "LambdaPolicy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${local.code_path}/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "lambda" {
    provider = aws.usa
    filename = "lambda_function_payload.zip"
    function_name = "hrdkorea-function"
    role = aws_iam_role.lambda.arn
    handler = "lambda_function.lambda_handler"
    timeout = "5"
    source_code_hash = data.archive_file.lambda.output_base64sha256
    runtime = "python3.12"
}

output "lambda" {
    value = aws_lambda_function.lambda.arn
}