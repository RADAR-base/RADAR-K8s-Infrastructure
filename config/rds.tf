resource "aws_db_subnet_group" "rds_subnet" {
  name       = "radar-base-${var.environment}-rds-subnet"
  subnet_ids = data.aws_subnets.private.ids
}

resource "aws_security_group" "rds_access" {
  name_prefix = "radar-base-${var.environment}-"
  description = "This security group is for accessing the RDS DB"
  vpc_id      = data.aws_vpc.main.id

  # ingress {
  #   from_port   = 5432
  #   to_port     = 5432
  #   protocol    = "tcp"
  #   cidr_blocks = ["188.28.81.208/32"]
  # }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [data.aws_security_group.node.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-rds-access" }), var.common_tags)

}

resource "aws_db_instance" "managementportal" {
  identifier                   = "radar-base-${var.environment}-managementportal"
  db_name                      = "managementportal"
  engine                       = "postgres"
  engine_version               = "13.7"
  instance_class               = "db.t4g.micro"
  username                     = "postgres"
  password                     = var.management_portal_postgres_password
  allocated_storage            = 5
  storage_type                 = "standard"
  storage_encrypted            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids       = [aws_security_group.rds_access.id]
  performance_insights_enabled = true

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-managementportal" }), var.common_tags)
}

resource "aws_db_instance" "appserver" {
  identifier                   = "radar-base-${var.environment}-appserver"
  db_name                      = "appserver"
  engine                       = "postgres"
  engine_version               = "13.7"
  instance_class               = "db.t4g.micro"
  username                     = "postgres"
  password                     = var.radar_appserver_postgres_password
  allocated_storage            = 5
  storage_type                 = "standard"
  storage_encrypted            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  multi_az                     = false
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids       = [aws_security_group.rds_access.id]
  performance_insights_enabled = true

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-appserver" }), var.common_tags)
}

resource "aws_db_instance" "rest_sources_auth" {
  identifier                   = "radar-base-${var.environment}-rest-sources-auth"
  db_name                      = "rest_sources_auth"
  engine                       = "postgres"
  engine_version               = "13.7"
  instance_class               = "db.t4g.micro"
  username                     = "postgres"
  password                     = var.radar_rest_sources_backend_postgres_password
  allocated_storage            = 5
  storage_type                 = "standard"
  storage_encrypted            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  multi_az                     = false
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet.name
  vpc_security_group_ids       = [aws_security_group.rds_access.id]
  performance_insights_enabled = true

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-rest-sources-auth" }), var.common_tags)
}

output "radar_base_rds_managementportal_host" {
  value = aws_db_instance.managementportal.address
}

output "radar_base_rds_managementportal_port" {
  value = aws_db_instance.managementportal.port
}

output "radar_base_rds_managementportal_user" {
  value = aws_db_instance.managementportal.username
}

output "radar_base_rds_appserver_host" {
  value = aws_db_instance.appserver.address
}

output "radar_base_rds_appserver_port" {
  value = aws_db_instance.appserver.port
}

output "radar_base_rds_appserver_user" {
  value = aws_db_instance.appserver.username
}

output "radar_base_rds_rest_sources_auth_host" {
  value = aws_db_instance.rest_sources_auth.address
}

output "radar_base_rds_rest_sources_auth_port" {
  value = aws_db_instance.rest_sources_auth.port
}

output "radar_base_rds_rest_sources_auth_user" {
  value = aws_db_instance.rest_sources_auth.username
}
