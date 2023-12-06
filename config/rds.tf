resource "aws_db_subnet_group" "rds_subnet" {
  count = var.enable_rds ? 1 : 0

  name       = "radar-base-${var.environment}-rds-subnet"
  subnet_ids = data.aws_subnets.private.ids
}

resource "aws_security_group" "rds_access" {
  count = var.enable_rds ? 1 : 0

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

  tags = merge(tomap({ "Name" : "radar-base-rds-access" }), var.common_tags)

}

resource "aws_db_instance" "radar_postgres" {
  count = var.enable_rds ? 1 : 0

  identifier                   = "radar-base-${var.environment}-postgres"
  db_name                      = "radarbase${var.environment}"
  engine                       = "postgres"
  engine_version               = var.postgres_version
  instance_class               = "db.t4g.micro"
  username                     = "postgres"
  password                     = var.radar_postgres_password
  allocated_storage            = 5
  storage_type                 = "standard"
  storage_encrypted            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  multi_az                     = false
  db_subnet_group_name         = aws_db_subnet_group.rds_subnet[0].name
  vpc_security_group_ids       = [aws_security_group.rds_access[0].id]
  performance_insights_enabled = true

  tags = merge(tomap({ "Name" : "radar-base-appserver" }), var.common_tags)
}

resource "kubectl_manifest" "create_databases" {
  count = var.enable_rds ? 1 : 0
  
  yaml_body = <<-YAML
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: create-radar-postgres-databases
    spec:
      template:
        spec:
          containers:
            - name: radar-postgres-db-creator
              image: postgres:${var.postgres_version}
              command:
                - "bash"
                - "-c"
                - |
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase${var.environment} -c 'CREATE DATABASE managementportal;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase${var.environment} -c 'CREATE DATABASE appserver;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase${var.environment} -c 'CREATE DATABASE rest_sources_auth;'
          restartPolicy: Never
  YAML

  depends_on = [
    aws_db_instance.radar_postgres
  ]
}

output "radar_base_rds_managementportal_host" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].address : ""
}

output "radar_base_rds_managementportal_port" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].port : ""
}

output "radar_base_rds_managementportal_username" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].username : ""
}

output "radar_base_rds_managementportal_password" {
  value     = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].password : ""
  sensitive = true
}

output "radar_base_rds_appserver_host" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].address : ""
}

output "radar_base_rds_appserver_port" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].port : ""
}

output "radar_base_rds_appserver_username" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].username : ""
}

output "radar_base_rds_appserver_password" {
  value     = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].password : ""
  sensitive = true
}

output "radar_base_rds_rest_sources_auth_host" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].address : ""
}

output "radar_base_rds_rest_sources_auth_port" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].port : ""
}

output "radar_base_rds_rest_sources_auth_username" {
  value = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].username : ""
}

output "radar_base_rds_rest_sources_auth_password" {
  value     = aws_db_instance.radar_postgres != [] ? aws_db_instance.radar_postgres[0].password : ""
  sensitive = true
}
