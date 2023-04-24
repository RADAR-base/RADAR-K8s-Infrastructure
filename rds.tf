resource "aws_db_subnet_group" "radar_base_dev_rds_subnet" {
  name       = "radar-base-dev-rds-subnet"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds_access" {
  name_prefix = "radar-base-${var.environment}-"
  description = "This security group is for accessing the RDS DB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["188.28.81.208/32"]
  }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-rds-access" }), var.common_tags)

}

resource "aws_db_instance" "radar_base_postgres" {
  identifier                   = "radar-base-${var.environment}-postgres"
  engine                       = "postgres"
  engine_version               = "13.7"
  instance_class               = "db.t4g.micro"
  username                     = "postgres"
  password                     = "change_me"
  allocated_storage            = 5
  storage_type                 = "standard"
  storage_encrypted            = true
  skip_final_snapshot          = true
  publicly_accessible          = false
  db_subnet_group_name         = aws_db_subnet_group.radar_base_dev_rds_subnet.name
  vpc_security_group_ids       = [aws_security_group.rds_access.id]
  performance_insights_enabled = true

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-postgres" }), var.common_tags)
}