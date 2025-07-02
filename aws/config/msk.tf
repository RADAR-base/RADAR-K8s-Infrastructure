resource "aws_iam_role" "msk_role" {
  count = var.enable_msk ? 1 : 0

  name = "${var.eks_cluster_name}-msk-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "kafka.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-msk-role" }), var.common_tags)
}

resource "aws_iam_role_policy_attachment" "msk_policy_attachment" {
  count = var.enable_msk ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
  role       = aws_iam_role.msk_role[0].name
}

resource "aws_security_group" "msk_cluster_access" {
  count = var.enable_msk ? 1 : 0

  name_prefix = "${var.eks_cluster_name}-msk-"

  description = "This security group is for accessing the MSK cluster"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [data.aws_security_group.node.id]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [data.aws_security_group.node.id]
  }

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-msk-cluster-access-sg" }), var.common_tags)
}

resource "aws_msk_configuration" "msk_configuration" {
  count = var.enable_msk ? 1 : 0

  kafka_versions = [var.kafka_version]
  name           = "${var.eks_cluster_name}-msk-configuration"

  server_properties = <<PROPERTIES
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.io.threads=4
num.network.threads=3
num.partitions=1
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
PROPERTIES
}

resource "aws_cloudwatch_log_group" "msk_broker" {
  count = var.enable_msk_logging ? 1 : 0
  name  = "${var.eks_cluster_name}-msk-broker-logs"
}

#trivy:ignore:AVD-AWS-0074 Logging on MSK brokers can be enabled by setting var.enable_msk_logging to true
#trivy:ignore:AVD-AWS-0179 By default an AWS-managed KMS key is used to encrypt MSK data at rest
resource "aws_msk_cluster" "msk_cluster" {
  count = var.enable_msk ? 1 : 0

  cluster_name = "${var.eks_cluster_name}-msk-cluster"

  kafka_version          = var.kafka_version
  number_of_broker_nodes = 3
  enhanced_monitoring    = "DEFAULT"

  broker_node_group_info {
    instance_type = "kafka.t3.small"
    storage_info {
      ebs_storage_info {
        volume_size = 2
      }
    }
    client_subnets  = data.aws_subnets.private.ids
    security_groups = [data.aws_security_group.vpc_default.id, aws_security_group.msk_cluster_access[0].id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  client_authentication {
    unauthenticated = true
    sasl {
      iam   = true
      scram = false
    }
  }

  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.msk_configuration[0].arn
    revision = 1
  }

  dynamic "logging_info" {
    for_each = var.enable_msk_logging ? [1] : []
    content {
      broker_logs {
        cloudwatch_logs {
          enabled   = var.enable_msk_logging
          log_group = aws_cloudwatch_log_group.msk_broker.name
        }
      }
    }
  }
}

output "radar_base_msk_bootstrap_brokers" {
  value = var.enable_msk ? aws_msk_cluster.msk_cluster[0].bootstrap_brokers_tls : null
}

output "radar_base_msk_zookeeper_connect" {
  value = var.enable_msk ? aws_msk_cluster.msk_cluster[0].zookeeper_connect_string : null
}
