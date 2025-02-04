module "allow_eks_access_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=e20e0b9a42084bbc885fd5abb18b8744810bd567" # commit hash of version 5.48.0

  name          = "${var.eks_cluster_name}-allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",

          # # Further enable and narrow down access permissions below for your admin users.
          # "eks:*",
          # "ec2:*",
          # "iam:*",
          # "cloudwatch:*",
          # "kms:*",
          # "logs:*",
          # "autoscaling:*",
          # "elasticloadbalancing:*",
          # # For accessing optional resources
          # "rds:*",
          # "route53:*",
          # "ses:*",
          # "kafka:*",
          # "s3:*",
          # "sqs:*",
          # "events:*",
          # "sns:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-allow-eks-access" }), var.common_tags)
}

module "eks_admins_iam_role" {
  source           = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=e20e0b9a42084bbc885fd5abb18b8744810bd567" # commit hash of version 5.48.0
  role_description = "The administrative role for the EKS cluster"

  role_name         = "${var.eks_cluster_name}-admin-role"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-admin-role" }), var.common_tags)
}


module "allow_assume_eks_admins_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=e20e0b9a42084bbc885fd5abb18b8744810bd567" # commit hash of version 5.48.0

  name          = "${var.eks_cluster_name}-allow-assume-eks-admin-role"
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

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-allow-assume-eks-admin-role" }), var.common_tags)
}

resource "aws_iam_policy_attachment" "eks_admins_policy_attachment" {
  name       = "${var.eks_cluster_name}-eks-admins-policy-attachment"
  policy_arn = module.allow_assume_eks_admins_iam_policy.arn
  users      = var.eks_admins_group_users
}

module "iam_user" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-user?ref=e20e0b9a42084bbc885fd5abb18b8744810bd567" # commit hash of version 5.48.0

  name                          = "${var.eks_cluster_name}-ecr-readonly-user"
  create_iam_user_login_profile = false
  create_iam_access_key         = false
  force_destroy                 = false
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly",
  ]

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-ecr-readonly-user" }), var.common_tags)
}

resource "aws_iam_policy" "s3_access" {
  name = "${var.eks_cluster_name}-s3-access-policy"
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
          "arn:aws:s3:::${var.eks_cluster_name}-*/*",
        ]
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-s3-access-policy" }), var.common_tags)
}

resource "aws_iam_policy" "ecr_access" {
  name = "${var.eks_cluster_name}-ecr-access-policy"

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
          "ecr:DescribeImageScanFindings",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DeleteRepository",
          "ecr:BatchDeleteImage",
          "ecr:SetRepositoryPolicy",
          "ecr:DeleteRepositoryPolicy"
        ]
        Resource = [
          for repository_name in var.ecr_repository_names : "arn:aws:ecr:::repository/${repository_name}"
        ]
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-ecr-access-policy" }), var.common_tags)
}

resource "aws_iam_policy" "ecr_pull_through_cache" {
  name = "${var.eks_cluster_name}-ecr-pull-through-cache-policy"

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
      },
      {
        "Action" : ["secretsmanager:GetSecretValue"],
        "Effect" : "Allow",
        "Resource" : "arn:aws:secretsmanager:${var.AWS_REGION}::secret:ecr-pullthroughcache/radar-base-docker-hub*"
      }
    ]
  })

  tags = merge(tomap({ "Name" : "${var.eks_cluster_name}-ecr-pull-through-cache-policy" }), var.common_tags)

  #checkov:skip=CKV_AWS_355,CKV_AWS_290: Temporarily skip these checks
}
