mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}
mock_provider "random" {}

variables {
  eks_cluster_name = "radar-base-test"
  radar_postgres_password = "test"
  docker_hub_username     = "test"
  docker_hub_access_token = "test"
  ghcr_username           = "test"
  ghcr_access_token       = "test"
  domain_name = { "radar-base.test" = "Z0123456789ABCDEFGHIJ" }
  enable_metrics          = false
  enable_karpenter        = false
  enable_msk              = false
  enable_rds              = true
  enable_route53          = false
  enable_ses              = false
  enable_s3               = false
  enable_eip              = false
  enable_ecr_ptc          = false
  with_dmz_pods           = false
  ses_bounce_destinations = []

  AWS_ACCESS_KEY_ID       = "test"
  AWS_SECRET_ACCESS_KEY   = "test"
}

run "rds_plans_the_full_single_instance_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_db_instance.radar_postgres) == 1,
      length(aws_db_instance.radar_postgres_replicas) == 0,
      length(aws_db_subnet_group.rds_subnet) == 1,
      length(aws_security_group.rds_access) == 1,
      length(kubectl_manifest.create_databases_if_not_exist) == 1,
    ])
    error_message = "The enable_rds should plan one primary instance, one subnet group, one security group and one bootstrap job, and no replicas"
  }

  assert {
    condition = alltrue([
      aws_db_instance.radar_postgres[0].identifier == "${var.eks_cluster_name}-postgres",
      aws_db_instance.radar_postgres[0].db_name == "radarbase",
      aws_db_instance.radar_postgres[0].engine == "postgres",
      aws_db_instance.radar_postgres[0].instance_class == "db.t4g.micro",
      aws_db_instance.radar_postgres[0].username == "postgres",
    ])
    error_message = "The primary instance identity and engine settings do not match"
  }

  assert {
    condition = alltrue([
      aws_db_instance.radar_postgres[0].allocated_storage == 5,
      aws_db_instance.radar_postgres[0].storage_type == "gp3",
      aws_db_instance.radar_postgres[0].storage_encrypted,
      aws_db_instance.radar_postgres[0].publicly_accessible == false,
      aws_db_instance.radar_postgres[0].backup_retention_period == 7,
      aws_db_instance.radar_postgres[0].deletion_protection,
      aws_db_instance.radar_postgres[0].performance_insights_enabled,
      aws_db_instance.radar_postgres[0].iam_database_authentication_enabled,
      aws_db_instance.radar_postgres[0].copy_tags_to_snapshot,
      aws_db_instance.radar_postgres[0].allow_major_version_upgrade,
      aws_db_instance.radar_postgres[0].apply_immediately == false,
      aws_db_instance.radar_postgres[0].skip_final_snapshot,
    ])
    error_message = "The primary instance hardening flags should be set to the defaults"
  }

  assert {
    condition     = aws_db_instance.radar_postgres[0].multi_az == false
    error_message = "The multi_az should follow enable_rds_multi_az, which defaults to false"
  }

  assert {
    condition     = aws_db_instance.radar_postgres[0].engine_version == "14.22"
    error_message = "The engine_version should follow var.postgres_version"
  }
}

run "rds_subnet_group_spans_every_private_subnet" {
  command = plan

  assert {
    condition     = length(setsubtract(toset(aws_db_subnet_group.rds_subnet[0].subnet_ids), toset(data.aws_subnets.private.ids))) == 0
    error_message = "The RDS subnet group should only reference subnets found by data.aws_subnets.private"
  }

  assert {
    condition     = length(aws_db_subnet_group.rds_subnet[0].subnet_ids) == 3
    error_message = "The subnet group should span the three mocked private subnets"
  }

  assert {
    condition     = aws_db_subnet_group.rds_subnet[0].name == "${var.eks_cluster_name}-rds-subnet"
    error_message = "Unexpected subnet group name"
  }
}

run "rds_security_group_is_scoped_to_private_cidrs" {
  command = plan

  assert {
    condition     = aws_security_group.rds_access[0].vpc_id == data.aws_vpc.main.id
    error_message = "The RDS security group should live in the cluster VPC"
  }

  assert {
    condition     = toset(one(aws_security_group.rds_access[0].ingress).cidr_blocks) == toset(local.private_cidr_blocks)
    error_message = "Ingress should be limited to local.private_cidr_blocks"
  }

  assert {
    condition     = one(aws_security_group.rds_access[0].ingress).protocol == "tcp"
    error_message = "Ingress should be TCP only"
  }

  assert {
    condition     = toset(one(aws_security_group.rds_access[0].egress).cidr_blocks) == toset(local.private_cidr_blocks)
    error_message = "Egress should be limited to local.private_cidr_blocks"
  }
}

run "read_replicas_replicate_the_primary" {
  command = plan

  variables {
    postgres_read_replicas = 2
  }

  assert {
    condition     = length(aws_db_instance.radar_postgres_replicas) == 2
    error_message = "Should plan exactly two replicas"
  }

  assert {
    condition = alltrue([
      for k, replica in aws_db_instance.radar_postgres_replicas :
      replica.identifier == "radar-base-test-postgres-replica-${k}"
    ])
    error_message = "Replica identifiers should be indexed"
  }

  assert {
    condition = alltrue([
      for _, replica in aws_db_instance.radar_postgres_replicas :
      replica.engine == "postgres"
    ])
    error_message = "Replicas should inherit the engine from the primary instance"
  }

  assert {
    condition = alltrue([
      for _, replica in aws_db_instance.radar_postgres_replicas :
      replica.engine_version == aws_db_instance.radar_postgres[0].engine_version
    ])
    error_message = "Replicas should inherit the engine version from the primary instance"
  }

  assert {
    condition = alltrue([
      for _, replica in aws_db_instance.radar_postgres_replicas :
      replica.instance_class == aws_db_instance.radar_postgres[0].instance_class
    ])
    error_message = "Replicas should inherit the instance class from the primary instance"
  }

  assert {
    condition = alltrue([
      for _, replica in aws_db_instance.radar_postgres_replicas :
      replica.allocated_storage == 5 && replica.storage_type == "gp3" && replica.storage_encrypted
    ])
    error_message = "Replicas should inherit storage allocation, type and encryption from the primary instance"
  }

  assert {
    condition = alltrue([
      for _, replica in aws_db_instance.radar_postgres_replicas : replica.multi_az == false
    ])
    error_message = "Read replicas must stay single AZ"
  }
}

run "multi_az_flag_reaches_the_primary_only" {
  command = plan

  variables {
    enable_rds_multi_az    = true
    postgres_read_replicas = 1
  }

  assert {
    condition     = aws_db_instance.radar_postgres[0].multi_az == true
    error_message = "enable_rds_multi_az should set multi_az on the primary instance"
  }

  assert {
    condition     = aws_db_instance.radar_postgres_replicas[0].multi_az == false
    error_message = "Replicas should remain single-AZ when multi_az is enabled for the primary"
  }
}
run "replica_summary_output_tracks_the_replica_count" {
  command = plan

  assert {
    condition     = output.radar_base_rds_replicas_info == null
    error_message = "The radar_base_rds_replicas_info should be null when postgres_read_replicas is 0"
  }
}

run "replica_summary_output_is_populated_when_replicas_exist" {
  command = plan

  variables {
    postgres_read_replicas = 2
  }

  assert {
    condition     = length(output.radar_base_rds_replicas_info) == 2
    error_message = "The radar_base_rds_replicas_info should carry one entry per configured read replica"
  }
}

run "disabling_rds_removes_every_rds_resource" {
  command = plan

  variables {
    enable_rds = false
  }

  assert {
    condition = alltrue([
      length(aws_db_instance.radar_postgres) == 0,
      length(aws_db_instance.radar_postgres_replicas) == 0,
      length(aws_db_subnet_group.rds_subnet) == 0,
      length(aws_security_group.rds_access) == 0,
      length(kubectl_manifest.create_databases_if_not_exist) == 0,
      output.radar_base_rds_managementportal_host == null,
    ])
    error_message = "Turning enable_rds off should remove every RDS resource and null its outputs"
  }
}
