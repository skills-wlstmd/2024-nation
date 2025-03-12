resource "aws_security_group" "rds_sg" {
    name = "wsi-rds-sg"
    vpc_id =  aws_vpc.main.id

    ingress {
        from_port = 3307
        to_port = 3307
        protocol = "tcp"
        security_groups = [aws_security_group.bastion.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
    Name = "wsi-rds-sg"
  }
}

resource "aws_db_subnet_group" "db" {
    name = "wsi-sg"
    subnet_ids = [
        aws_subnet.protect_a.id,
        aws_subnet.protect_b.id
    ]
    
    tags = {
        Name = "wsi-rds-subnet-group"
    }
}

resource "aws_db_parameter_group" "pg" {
    name = "wsi-pg"
    family = "mysql8.0"
    parameter {
        name  = "general_log"
        value = "1"
    }
    parameter {
        name  = "Slow_query_log"
        value = "1"
    }
    parameter {
        name  = "Long_query_time"
        value = "5"
    }
    parameter {
        name  = "log_output"
        value = "TABLE"
    }
}

resource "aws_db_instance" "db" {
  apply_immediately = true
  identifier = "wsi-rds-mysql"
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.m5.xlarge"
  username             = "admin"
  manage_master_user_password = true
  parameter_group_name = aws_db_parameter_group.pg.name
  multi_az             = true
  storage_type         = "gp2"
  port = "3307"
  backup_retention_period = 7
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db.name
  skip_final_snapshot = true
  storage_encrypted = true
  db_name = "wsi"
  tags = {
    Name = "wsi-rds-mysql"
  }
}

resource "aws_secretsmanager_secret" "db" {
    name = "wsi/secret"
    recovery_window_in_days = 0 
    tags = {
        Name = "wsi/secret"
    }
}

resource "aws_secretsmanager_secret_version" "db" {
    secret_id     = aws_secretsmanager_secret.db.id
    secret_string = jsonencode({
      "host"                = aws_db_instance.db.address,
      "port"                = aws_db_instance.db.port,
      "dbname"              = aws_db_instance.db.db_name
      "aws_region"          = "ap-northeast-2"
    })
}