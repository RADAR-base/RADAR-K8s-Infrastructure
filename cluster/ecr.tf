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

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-ecr-access-policy" }), var.common_tags)
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

  tags = merge(tomap({ "Name" : "radar-base-${var.environment}-ecr-pull-through-cache-policy" }), var.common_tags)
}