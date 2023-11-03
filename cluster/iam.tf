module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.15.0"

  name          = "${var.environment}-radar-base-allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = merge(tomap({ "Name" : "radar-base-allow-eks-access" }), var.common_tags)
}

module "eks_admins_iam_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version          = "5.15.0"
  role_description = "The administrative role for the EKS cluster"

  role_name         = "${var.environment}-radar-base-admin-role"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]

  tags = merge(tomap({ "Name" : "radar-base-admin-role" }), var.common_tags)
}


module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.15.0"

  name          = "${var.environment}-radar-base-allow-assume-eks-admin-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })

  tags = merge(tomap({ "Name" : "radar-base-allow-assume-eks-admin-role" }), var.common_tags)
}

module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.15.0"

  name                              = "${var.environment}-radar-base-eks-admin-group"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = var.eks_admins_group_users
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]

  tags = merge(tomap({ "Name" : "radar-base-eks-admin-group" }), var.common_tags)
}

module "iam_user" {
  source = "terraform-aws-modules/iam/aws//modules/iam-user"

  name                          = "${var.environment}-radar-base-ecr-readonly-user"
  create_iam_user_login_profile = false
  create_iam_access_key         = true
  force_destroy                 = false
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly",
  ]

  tags = merge(tomap({ "Name" : "radar-base-ecr-readonly-user" }), var.common_tags)
}

resource "aws_iam_policy" "s3_access" {
  name = "radar-base-${var.environment}-s3-access-policy"
  path = "/eks/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::radar-base-${var.environment}-intermediate-output-storage/*",
          "arn:aws:s3:::radar-base-${var.environment}-output-storage/*",
          "arn:aws:s3:::radar-base-${var.environment}-velero-backups/*",
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_access" {
  name = "radar-base-${var.environment}-ecr-access-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(tomap({ "Name" : "radar-base-ecr-access-policy" }), var.common_tags)
}

resource "aws_iam_policy" "ecr_pull_through_cache" {
  name = "radar-base-${var.environment}-ecr-pull-through-cache-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:CreatePullThroughCacheRule",
          "ecr:BatchImportUpstreamImage",
          "ecr:CreateRepository"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(tomap({ "Name" : "radar-base-ecr-pull-through-cache-policy" }), var.common_tags)
}

resource "aws_iam_user" "smtp_user" {
  name = "${var.environment}-radar-base-smtp-user"
  tags = merge(tomap({ "Name" : "radar-base-smtp-user" }), var.common_tags)
}

resource "aws_iam_access_key" "smtp_user_key" {
  user = aws_iam_user.smtp_user.name
}

resource "aws_iam_policy" "smtp_user_policy" {
  name = "${var.environment}-radar-base-smtp-user-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "smtp_user_policy_attach" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.smtp_user_policy.arn
}
