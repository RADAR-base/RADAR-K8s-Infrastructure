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

#trivy:ignore:AVD-AWS-0077 Temporarly skip these checks
#trivy:ignore:AVD-AWS-0177 Temporarly skip these checks
#trivy:ignore:AVD-AWS-0176 Temporarly skip these checks
resource "aws_db_instance" "radar_postgres" {
  count = var.enable_rds ? 1 : 0

  identifier                   = "${var.eks_cluster_name}-postgres"
  db_name                      = "radarbase"
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
  copy_tags_to_snapshot        = true

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-postgres" }), var.common_tags)

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
