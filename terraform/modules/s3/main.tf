terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_s3_bucket" "this" {
  #checkov:skip=CKV_AWS_53: Block public ACLs enforced via aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_54: Block public policy enforced via aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_55: Ignore public ACLs enforced via aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_56: Restrict public buckets enforced via aws_s3_bucket_public_access_block
  #checkov:skip=CKV_AWS_21: Versioning enabled via aws_s3_bucket_versioning resource
  #checkov:skip=CKV_AWS_93: No bucket policy; access is IAM-only
  #checkov:skip=CKV_AWS_18: Access logging routes to a centralized audit bucket outside this module
  #checkov:skip=CKV2_AWS_62: Event notifications not required for state/artifact buckets
  #checkov:skip=CKV_AWS_145: KMS applied when kms_key_id provided; AES256 fallback is acceptable
  #checkov:skip=CKV_AWS_144: Cross-region replication managed at org level, not per-module
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  })
}

data "aws_caller_identity" "current" {}

# Block all public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption (AES256)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = true
  }
}

# Versioning enabled
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"

    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
