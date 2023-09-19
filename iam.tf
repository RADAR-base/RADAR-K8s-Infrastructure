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

  tags = merge(tomap({ "Name" : "${var.environment}-radar-base-allow-eks-access" }), var.common_tags)
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

  tags = merge(tomap({ "Name" : "${var.environment}-radar-base-admin-role" }), var.common_tags)
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

  tags = merge(tomap({ "Name" : "${var.environment}-radar-base-allow-assume-eks-admin-role" }), var.common_tags)
}

module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.15.0"

  name                              = "${var.environment}-radar-base-eks-admin-group"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = var.eks_admins_group_users
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]

  tags = merge(tomap({ "Name" : "${var.environment}-radar-base-eks-admin-group" }), var.common_tags)
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

  tags = merge(tomap({ "Name" : "${var.environment}-radar-base-ecr-readonly-user" }), var.common_tags)
}

output "ecr_readonly_user_key_id" {
  value     = module.iam_user.iam_access_key_id
  sensitive = true
}

output "ecr_readonly_user_key_secret" {
  value     = module.iam_user.iam_access_key_secret
  sensitive = true
}