locals {
  private_cidr_blocks = [
    for subnet_id in data.aws_subnets.private.ids : data.aws_subnet.private_subnet[subnet_id].cidr_block
  ]
}

resource "aws_db_subnet_group" "rds_subnet" {
  count = var.enable_rds ? 1 : 0

  name       = "${var.eks_cluster_name}-rds-subnet"
  subnet_ids = data.aws_subnets.private.ids
}

resource "aws_security_group" "rds_access" {
  count = var.enable_rds ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-"
  description = "This security group is for accessing the RDS DB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = local.private_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.private_cidr_blocks
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-rds-access" }), var.common_tags)

}

resource "aws_db_instance" "radar_postgres" {
  count = var.enable_rds ? 1 : 0

  identifier                          = "${var.eks_cluster_name}-postgres"
  db_name                             = "radarbase"
  engine                              = "postgres"
  engine_version                      = var.postgres_version
  instance_class                      = "db.t4g.micro"
  username                            = "postgres"
  password                            = var.radar_postgres_password
  allocated_storage                   = 5
  storage_type                        = "gp3"
  storage_encrypted                   = true
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  multi_az                            = var.enable_rds_multi_az
  db_subnet_group_name                = aws_db_subnet_group.rds_subnet[0].name
  vpc_security_group_ids              = [aws_security_group.rds_access[0].id]
  performance_insights_enabled        = true
  copy_tags_to_snapshot               = true
  backup_retention_period             = 7
  iam_database_authentication_enabled = true
  deletion_protection                 = true  # This needs to be set to false before you really want to delete the database with "terraform destroy"
  apply_immediately                   = false # If set to true, it will not wait for the next maintenance window and can result in a downtime

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-postgres" }), var.common_tags)

  #checkov:skip=CKV2_AWS_30: This will result in extra charge and should be only enabled for troubleshooting and stringent auditing
}

resource "aws_db_instance" "radar_postgres_replicas" {
  count = var.enable_rds ? var.postgres_read_replicas : 0

  identifier                          = "${var.eks_cluster_name}-postgres-replica-${count.index}"
  replicate_source_db                 = aws_db_instance.radar_postgres[0].arn
  engine                              = aws_db_instance.radar_postgres[0].engine
  engine_version                      = aws_db_instance.radar_postgres[0].engine_version
  instance_class                      = aws_db_instance.radar_postgres[0].instance_class
  allocated_storage                   = aws_db_instance.radar_postgres[0].allocated_storage
  storage_type                        = aws_db_instance.radar_postgres[0].storage_type
  storage_encrypted                   = aws_db_instance.radar_postgres[0].storage_encrypted
  skip_final_snapshot                 = aws_db_instance.radar_postgres[0].skip_final_snapshot
  publicly_accessible                 = aws_db_instance.radar_postgres[0].publicly_accessible
  multi_az                            = false
  db_subnet_group_name                = aws_db_instance.radar_postgres[0].db_subnet_group_name
  vpc_security_group_ids              = aws_db_instance.radar_postgres[0].vpc_security_group_ids
  performance_insights_enabled        = aws_db_instance.radar_postgres[0].performance_insights_enabled
  copy_tags_to_snapshot               = aws_db_instance.radar_postgres[0].copy_tags_to_snapshot
  backup_retention_period             = aws_db_instance.radar_postgres[0].backup_retention_period
  iam_database_authentication_enabled = aws_db_instance.radar_postgres[0].iam_database_authentication_enabled
  deletion_protection                 = aws_db_instance.radar_postgres[0].deletion_protection
  apply_immediately                   = aws_db_instance.radar_postgres[0].apply_immediately

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-postgres-replica-${count.index}" }), var.common_tags)

  #checkov:skip=CKV2_AWS_30: This will result in extra charge and should be only enabled for troubleshooting and stringent auditing
}

resource "kubectl_manifest" "create_databases_if_not_exist" {
  count = var.enable_rds ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: batch/v1
    kind: Job
    metadata:
      name: create-radar-postgres-databases-if-not-exist
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
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase -c 'CREATE DATABASE managementportal;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase -c 'CREATE DATABASE appserver;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase -c 'CREATE DATABASE rest_sources_auth;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase -c 'CREATE DATABASE kratos;'
                  PGPASSWORD=${var.radar_postgres_password} psql --host=${aws_db_instance.radar_postgres[0].address} --port=5432 --username=${aws_db_instance.radar_postgres[0].username} --dbname=radarbase -c 'CREATE DATABASE hydra;'
                  true
          restartPolicy: Never
      activeDeadlineSeconds: 60
      ttlSecondsAfterFinished: 60
  YAML

  depends_on = [
    aws_db_instance.radar_postgres
  ]
}

output "radar_base_rds_managementportal_host" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].address : null
}

output "radar_base_rds_managementportal_port" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].port : null
}

output "radar_base_rds_managementportal_username" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].username : null
}

output "radar_base_rds_managementportal_password" {
  value     = var.enable_rds ? aws_db_instance.radar_postgres[0].password : null
  sensitive = true
}

output "radar_base_rds_appserver_host" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].address : null
}

output "radar_base_rds_appserver_port" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].port : null
}

output "radar_base_rds_appserver_username" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].username : null
}

output "radar_base_rds_appserver_password" {
  value     = var.enable_rds ? aws_db_instance.radar_postgres[0].password : null
  sensitive = true
}

output "radar_base_rds_rest_sources_auth_host" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].address : null
}

output "radar_base_rds_rest_sources_auth_port" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].port : null
}

output "radar_base_rds_rest_sources_auth_username" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].username : null
}

output "radar_base_rds_rest_sources_auth_password" {
  value     = var.enable_rds ? aws_db_instance.radar_postgres[0].password : null
  sensitive = true
}

output "radar_base_rds_kratos_host" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].address : null
}

output "radar_base_rds_kratos_port" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].port : null
}

output "radar_base_rds_kratos_username" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].username : null
}

output "radar_base_rds_kratos_password" {
  value     = var.enable_rds ? aws_db_instance.radar_postgres[0].password : null
  sensitive = true
}

output "radar_base_rds_hydra_host" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].address : null
}

output "radar_base_rds_hydra_port" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].port : null
}

output "radar_base_rds_hydra_username" {
  value = var.enable_rds ? aws_db_instance.radar_postgres[0].username : null
}

output "radar_base_rds_hydra_password" {
  value     = var.enable_rds ? aws_db_instance.radar_postgres[0].password : null
  sensitive = true
}

output "radar_base_rds_replicas_info" {
  value = (
    var.enable_rds && var.postgres_read_replicas > 0
    ? [
      for replica in aws_db_instance.radar_postgres_replicas :
      {
        host     = replica.address
        port     = replica.port
        username = replica.username
        password = replica.password
        zone     = replica.availability_zone
      }
    ]
    : null
  )
  sensitive = true
}
