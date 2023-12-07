resource "aws_iam_role" "msk_role" {
  count = var.enable_msk ? 1 : 0

  name = "${var.environment}-msk-role"

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

  tags = merge(tomap({ "Name" : "msk-role" }), var.common_tags)
}

resource "aws_iam_role_policy_attachment" "msk_policy_attachment" {
  count = var.enable_msk ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonMSKFullAccess"
  role       = aws_iam_role.msk_role[0].name
}

resource "aws_security_group" "msk_cluster_access" {
  count = var.enable_msk ? 1 : 0

  name_prefix = "${var.environment}-radar-base-msk-"
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

  tags = merge(tomap({ "Name" : "msk-cluster-access-sg" }), var.common_tags)
}

resource "aws_msk_configuration" "msk_configuration" {
  count = var.enable_msk ? 1 : 0

  kafka_versions = [var.kafka_version]
  name           = "radar-base-${var.environment}-msk-configuration"

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

resource "aws_msk_cluster" "msk_cluster" {
  count = var.enable_msk ? 1 : 0

  cluster_name           = "radar-base-${var.environment}"
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
}

output "radar_base_msk_bootstrap_brokers" {
  value = var.enable_msk ? aws_msk_cluster.msk_cluster[0].bootstrap_brokers_tls : null
}

output "radar_base_msk_zookeeper_connect" {
  value = var.enable_msk ? aws_msk_cluster.msk_cluster[0].zookeeper_connect_string : null
}
