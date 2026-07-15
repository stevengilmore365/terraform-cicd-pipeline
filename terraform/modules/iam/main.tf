terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# IAM Users (environment-specific admin access)
resource "aws_iam_user" "admin" {
  name          = "${var.project_name}-${var.environment}-admin"
  path          = "/${var.environment}/"
  force_destroy = true

  tags = var.tags
}

# IAM Policy — scoped to project resources only
resource "aws_iam_user_policy" "admin" {
  name = "${var.project_name}-${var.environment}-admin-policy"
  user = aws_iam_user.admin.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Sid    = "AllowEC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-1"
          }
        }
      }
    ]
  })
}

# IAM Group for environment team
resource "aws_iam_group" "team" {
  name = "${var.project_name}-${var.environment}-team"
  path = "/${var.environment}/"
}

resource "aws_iam_group_membership" "admin" {
  name  = "${var.project_name}-${var.environment}-admin-membership"
  group = aws_iam_group.team.name
  users = [aws_iam_user.admin.name]
}

resource "aws_iam_group_policy" "team_readonly" {
  name  = "${var.project_name}-${var.environment}-readonly"
  group = aws_iam_group.team.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadOnly"
        Effect   = "Allow"
        Action   = ["s3:Get*", "s3:List*", "ec2:Describe*"]
        Resource = "*"
      }
    ]
  })
}
