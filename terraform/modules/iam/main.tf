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
  #checkov:skip=CKV_AWS_273: IAM users used for CI/CD service accounts; SSO is org-level and out of scope for this module
  name          = "${var.project_name}-${var.environment}-admin"
  path          = "/${var.environment}/"
  force_destroy = true

  tags = var.tags
}

# IAM Policy — scoped to project resources only
resource "aws_iam_user_policy" "admin" {
  #checkov:skip=CKV_AWS_40: Inline policy on user is intentional for scoped CI/CD service accounts; group policy also applied
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
  #checkov:skip=CKV2_AWS_14: Group membership managed via aws_iam_group_membership resource below
  name = "${var.project_name}-${var.environment}-team"
  path = "/${var.environment}/"
}

resource "aws_iam_group_membership" "admin" {
  #checkov:skip=CKV2_AWS_14: Group has member (aws_iam_user.admin); Checkov cannot resolve cross-resource membership from this resource type
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
        Sid    = "AllowS3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-*",
          "arn:aws:s3:::${var.project_name}-*/*"
        ]
      },
      {
        Sid    = "AllowEC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs"
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
