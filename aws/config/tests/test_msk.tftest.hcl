mock_provider "aws" {
  source = "./tests/mocks"
}

mock_provider "archive" {}
mock_provider "helm" {}
mock_provider "kubectl" {}
mock_provider "kubernetes" {}

mock_provider "random" {
  mock_resource "random_id" {
    defaults = {
      hex = "a1b2c3d4"
    }
  }
}

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
  enable_msk              = true
  enable_msk_logging      = false
  enable_rds              = false
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

run "msk_plans_the_full_cluster_graph" {
  command = plan

  assert {
    condition = alltrue([
      length(aws_iam_role.msk_role) == 1,
      length(aws_iam_role_policy_attachment.msk_policy_attachment) == 1,
      length(random_id.msk_config) == 1,
      length(aws_security_group.msk_cluster_access) == 1,
      length(aws_msk_configuration.msk_configuration) == 1,
      length(aws_msk_cluster.msk_cluster) == 1,
    ])
    error_message = "The enable_msk should plan the role, security group, configuration and cluster"
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.msk_broker) == 0
    error_message = "The broker log group should only exist when enable_msk_logging is true"
  }

  assert {
    condition = alltrue([
      aws_msk_cluster.msk_cluster[0].cluster_name == "radar-base-test-msk-cluster",
      aws_msk_cluster.msk_cluster[0].number_of_broker_nodes == 3,
      aws_msk_cluster.msk_cluster[0].kafka_version == "3.9.x",
      aws_msk_cluster.msk_cluster[0].enhanced_monitoring == "DEFAULT",
    ])
    error_message = "Cluster name, broker count, Kafka version or monitoring should match"
  }

  assert {
    condition     = one(aws_msk_cluster.msk_cluster[0].broker_node_group_info).instance_type == "kafka.t3.small"
    error_message = "The broker node group should use kafka.t3.small"
  }

  assert {
    condition = length(setsubtract(
      toset(one(aws_msk_cluster.msk_cluster[0].broker_node_group_info).client_subnets),
      toset(data.aws_subnets.private.ids),
    )) == 0
    error_message = "Brokers should only span subnets found by data.aws_subnets.private"
  }

  assert {
    condition     = length(one(aws_msk_cluster.msk_cluster[0].broker_node_group_info).client_subnets) == 3
    error_message = "Brokers should span all three private subnets"
  }
}

run "msk_cluster_is_encrypted_in_transit" {
  command = plan

  assert {
    condition     = one(aws_msk_cluster.msk_cluster[0].encryption_info).encryption_in_transit[0].client_broker == "TLS"
    error_message = "Client broker traffic should require TLS"
  }

  assert {
    condition     = one(aws_msk_cluster.msk_cluster[0].encryption_info).encryption_in_transit[0].in_cluster
    error_message = "In-cluster traffic should be encrypted"
  }

  assert {
    condition = alltrue([
      one(aws_msk_cluster.msk_cluster[0].client_authentication).sasl[0].iam,
      one(aws_msk_cluster.msk_cluster[0].client_authentication).sasl[0].scram == false,
      one(aws_msk_cluster.msk_cluster[0].client_authentication).unauthenticated,
    ])
    error_message = "MSK should authenticate with IAM SASL, disable SCRAM and allow unauthenticated access"
  }
}

run "msk_prometheus_exporters_are_enabled" {
  command = plan

  assert {
    condition = alltrue([
      one(one(one(aws_msk_cluster.msk_cluster[0].open_monitoring).prometheus).jmx_exporter).enabled_in_broker,
      one(one(one(aws_msk_cluster.msk_cluster[0].open_monitoring).prometheus).node_exporter).enabled_in_broker,
    ])
    error_message = "Both the JMX and node exporters should be enabled in the broker"
  }
}

run "msk_configuration_carries_the_broker_properties" {
  command = plan

  assert {
    condition     = toset(aws_msk_configuration.msk_configuration[0].kafka_versions) == toset(["3.9.x"])
    error_message = "The MSK configuration should target the configured Kafka version"
  }

  assert {
    condition = contains(
      split("\n", trimspace(aws_msk_configuration.msk_configuration[0].server_properties)),
      "auto.create.topics.enable=false",
    )
    error_message = "The server_properties should disable automatic topic creation"
  }

  assert {
    condition = contains(
      split("\n", trimspace(aws_msk_configuration.msk_configuration[0].server_properties)),
      "default.replication.factor=3",
    )
    error_message = "The server_properties should set a replication factor of 3"
  }

  assert {
    condition = contains(
      split("\n", trimspace(aws_msk_configuration.msk_configuration[0].server_properties)),
      "unclean.leader.election.enable=true",
    )
    error_message = "The server_properties should match the broker tuning committed"
  }

  assert {
    condition     = one(aws_msk_cluster.msk_cluster[0].configuration_info).revision == 1
    error_message = "The cluster should use revision 1 of the managed configuration"
  }
}

run "msk_security_group_only_allows_the_node_group" {
  command = plan

  assert {
    condition     = aws_security_group.msk_cluster_access[0].vpc_id == data.aws_vpc.main.id
    error_message = "The MSK access security group should live in the cluster VPC"
  }

  assert {
    condition = alltrue([
      toset(one(aws_security_group.msk_cluster_access[0].ingress).security_groups) == toset([data.aws_security_group.node.id]),
      toset(one(aws_security_group.msk_cluster_access[0].egress).security_groups) == toset([data.aws_security_group.node.id]),
    ])
    error_message = "Ingress and egress should be restricted to the EKS node security group"
  }
}

run "msk_role_trusts_kafka" {
  command = plan

  assert {
    condition = alltrue([
      for statement in jsondecode(aws_iam_role.msk_role[0].assume_role_policy).Statement :
      statement.Principal.Service == "kafka.amazonaws.com"
    ])
    error_message = "The MSK role should trust kafka.amazonaws.com"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.msk_policy_attachment[0].policy_arn == "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
    error_message = "The MSK role should be attached the AmazonMSKFullAccess managed policy"
  }
}

run "disabling_msk_removes_every_msk_resource" {
  command = plan

  variables {
    enable_msk = false
  }

  assert {
    condition = alltrue([
      length(aws_msk_cluster.msk_cluster) == 0,
      length(aws_msk_configuration.msk_configuration) == 0,
      length(aws_security_group.msk_cluster_access) == 0,
      length(aws_iam_role.msk_role) == 0,
      length(random_id.msk_config) == 0,
      output.radar_base_msk_bootstrap_brokers == null,
      output.radar_base_msk_zookeeper_connect == null,
    ])
    error_message = "Turning enable_msk off should remove every MSK resource and null its outputs"
  }
}
