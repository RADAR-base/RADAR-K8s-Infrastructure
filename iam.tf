module "allow_eks_access_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.15.0"

  name          = "dev-allow-eks-access"
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

  tags = {
    Name    = "dev-allow-eks-access"
    Project = "radar-base-development"
  }
}

module "eks_admins_iam_role" {
  source           = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version          = "5.15.0"
  role_description = "The administrative role for the EKS staging cluster - stage-cluster-1"

  role_name         = "dev-eks-admin-role"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${module.vpc.vpc_owner_id}:root"
  ]

  tags = {
    Name    = "dev-eks-admin-role"
    Project = "radar-base-development"
  }
}


module "allow_assume_eks_admins_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.15.0"

  name          = "dev-allow-assume-eks-admin-role"
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

  tags = {
    Name    = "dev-allow-assume-eks-admin-role"
    Project = "radar-base-development"
  }
}

module "eks_admins_iam_group" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-group-with-policies"
  version = "5.15.0"

  name                              = "dev-eks-admin-group"
  attach_iam_self_management_policy = false
  create_group                      = true
  group_users                       = ["username"]
  custom_group_policy_arns          = [module.allow_assume_eks_admins_iam_policy.arn]

  tags = {
    Name    = "dev-eks-admin-group"
    Project = "radar-base-development"
  }
}