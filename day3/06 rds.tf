resource "aws_security_group" "db" {
  name        = "apdev-RDS-SG"
  description = "apdev-RDS-SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 3306
    to_port    = 3306
  }

  egress {
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "apdev-RDS-SG"
  }
}

resource "aws_security_group" "db-proxy" {
  name        = "apdev-RDS-Proxy-SG"
  description = "apdev-RDS-Proxy-SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 3306
    to_port    = 3306
  }

  egress {
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "apdev-RDS-Proxy-SG"
  }
}

resource "aws_db_subnet_group" "db" {
  name = "apdev-rds-sg"
  subnet_ids = [
    aws_subnet.data_a.id,
    aws_subnet.data_b.id
  ]

  tags = {
    Name = "apdev-rds-sg"
  }
}

resource "aws_db_option_group" "db" {
  name                     = "apdev-rds-og"
  option_group_description = "apdev-rds-og"
  engine_name              = "mysql"
  major_engine_version     = "8.0"

  tags = {
    Name = "apdev-rds-og"
  }
}

resource "aws_db_parameter_group" "db" {
  name                    = "apdev-rds-pg"
  description             = "apdev-rds-pg"
  family                  = "mysql8.0"

  tags = {
    Name = "apdev-rds-pg"
  }
}

resource "aws_kms_key" "rds" {
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7

  tags = {
    Name = "rds-kms"
  }
}

resource "aws_kms_alias" "rds" {
  target_key_id          = aws_kms_key.rds.key_id
  name                   = "alias/rds-kms"
}

resource "aws_db_instance" "db" {
  identifier             = "apdev-rds-instance"
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "mysql"
  db_name                = "dev"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username               = "admin"
  password               = "Skill53##"
  port                   = 3306
  skip_final_snapshot    = true
  multi_az               = true
  storage_encrypted      = true
  publicly_accessible    = false
  db_subnet_group_name   = aws_db_subnet_group.db.name
  option_group_name      = aws_db_option_group.db.name
  parameter_group_name   = aws_db_parameter_group.db.name
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_db_proxy" "db" {
  name                   = "apdev-rds-proxy"
  engine_family          = "MYSQL"
  role_arn               = aws_iam_role.db.arn
  vpc_security_group_ids = [aws_security_group.db-proxy.id]
  vpc_subnet_ids         = [
    aws_subnet.data_a.id,
    aws_subnet.data_b.id
  ]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db.arn
  }

  depends_on = [
    aws_db_instance.db,
    aws_iam_role.db,
  ]

  tags = {
    Name = "apdev-rds-proxy"
  }
}

resource "aws_db_proxy_default_target_group" "db" {
  db_proxy_name = aws_db_proxy.db.name

  connection_pool_config {
    connection_borrow_timeout    = 300
    max_connections_percent      = 100
    session_pinning_filters      = []
  }
}

resource "aws_db_proxy_target" "rds_proxy" {
  db_instance_identifier = aws_db_instance.db.identifier
  db_proxy_name          = aws_db_proxy.db.name
  target_group_name      = aws_db_proxy_default_target_group.db.name
}
 
resource "aws_secretsmanager_secret" "db" {
  name = "rds-secret"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    "username" = aws_db_instance.db.username,
    "password" = aws_db_instance.db.password,
    "engine"   = aws_db_instance.db.engine,
    "host"     = aws_db_instance.db.address,
    "port"     = aws_db_instance.db.port,
    "dbname"   = aws_db_instance.db.db_name,
    "proxy_host" = aws_db_proxy.db.endpoint,
    "proxy_port" = "3306"
    "ssl"      = "true"
  })
}

resource "aws_iam_role" "db" {
  name = "rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "db" {
  name   = "rds-proxy-policy"
  role   = aws_iam_role.db.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = "${aws_secretsmanager_secret.db.arn}"
      },
      {
        Action = [
          "rds-db:connect"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "kms:Decrypt"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}