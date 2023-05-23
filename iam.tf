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
