resource "aws_security_group" "db" {
  name        = "wsc2024-RDS-SG"
  description = "wsc2024-RDS-SG"
  vpc_id      = aws_vpc.storage.id

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
    Name = "wsc2024-RDS-SG"
  }
}

resource "aws_db_subnet_group" "db" {
  name = "wsc2024-rds-sg"
  subnet_ids = [
    aws_subnet.storage_a.id,
    aws_subnet.storage_b.id
  ]

  tags = {
    Name = "wsc2024-rds-sg"
  }
}

resource "aws_rds_cluster_parameter_group" "db" {
  name        = "wsc2024-rds-cpg"
  description = "wsc2024-rds-cpg"
  family      = "aurora-mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Seoul"
  }

  tags = {
    Name = "wsc2024-rds-cpg"
  }
}

resource "aws_db_parameter_group" "db" {
  name        = "wsc2024-rds-pg"
  description = "wsc2024-rds-pg"
  family      = "aurora-mysql8.0"

  tags = {
    Name = "wsc2024-rds-pg"
  }
}

resource "aws_rds_cluster" "db" {
  cluster_identifier          = "wsc2024-db-cluster"
  database_name               = "wsc2024_db"
  availability_zones          = ["us-east-1a", "us-east-1b"]
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.db.name
  db_instance_parameter_group_name = aws_db_parameter_group.db.name
  enabled_cloudwatch_logs_exports  = ["audit", "error", "general", "slowquery"]
  backtrack_window            = 14400
  engine                      = "aurora-mysql"
  master_username             = "admin"
  master_password             = "Skill53##"
  skip_final_snapshot         = true
  storage_encrypted           = true
  port                        = 3306

  tags = {
    Name = "wsc2024-db-cluster"
  }

  lifecycle {
    ignore_changes = [
      "availability_zones",
      "db_cluster_parameter_group_name",
      "db_instance_parameter_group_name"
    ]
  }
}



resource "aws_rds_cluster_instance" "db" {
  count                   = 2
  cluster_identifier      = aws_rds_cluster.db.id
  db_subnet_group_name    = aws_db_subnet_group.db.name
  instance_class          = "db.t3.medium"
  identifier              = "wsc2024-db-cluster-${count.index}"
  engine                  = "aurora-mysql"

  tags = {
    Name = "wsc2024-db-cluster-${count.index}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_secretsmanager_secret" "secret" {
  name = "db-secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "secret" {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    "username"            = aws_rds_cluster.db.master_username
    "password"            = aws_rds_cluster.db.master_password
    "engine"              = aws_rds_cluster.db.engine
    "host"                = aws_rds_cluster.db.endpoint
    "port"                = aws_rds_cluster.db.port
    "dbClusterIdentifier" = aws_rds_cluster.db.cluster_identifier
    "dbname"              = aws_rds_cluster.db.database_name
    "aws_region"          = "us-east-1"
  })
}

output "security_group" {
  value = aws_security_group.db.id
}

output "subnet_group" {
  value = aws_db_subnet_group.db.id
}

output "cluster_parameter_group" {
  value = aws_rds_cluster_parameter_group.db.id
}

output "parameter_group" {
  value = aws_db_parameter_group.db.id
}

output "rds_cluster" {
  value = aws_rds_cluster.db.id
}

output "rds_secret_manager" {
  value = aws_secretsmanager_secret.secret.id
}