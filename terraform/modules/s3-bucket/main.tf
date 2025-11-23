terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# S3 Bucket for Media Storage
resource "aws_s3_bucket" "media" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name    = var.bucket_name
      Purpose = "Media Storage"
    }
  )
}

# Enable versioning for data protection
resource "aws_s3_bucket_versioning" "media" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = var.sse_algorithm == "aws:kms" ? var.kms_master_key_id : null
    }
    bucket_key_enabled = var.sse_algorithm == "aws:kms" ? true : null
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "media" {
  count  = var.enable_lifecycle_rules ? 1 : 0
  bucket = aws_s3_bucket.media.id

  # Transition to Intelligent-Tiering after 0 days (immediate)
  dynamic "rule" {
    for_each = var.enable_intelligent_tiering ? [1] : []
    content {
      id     = "intelligent-tiering"
      status = "Enabled"

      filter {}

      transition {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  }

  # Transition infrequently accessed objects to IA
  dynamic "rule" {
    for_each = var.transition_to_ia_days > 0 ? [1] : []
    content {
      id     = "transition-to-ia"
      status = "Enabled"

      filter {}

      transition {
        days          = var.transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }
  }

  # Transition old objects to Glacier
  dynamic "rule" {
    for_each = var.transition_to_glacier_days > 0 ? [1] : []
    content {
      id     = "transition-to-glacier"
      status = "Enabled"

      filter {}

      transition {
        days          = var.transition_to_glacier_days
        storage_class = "GLACIER_FLEXIBLE_RETRIEVAL"
      }
    }
  }

  # Expire old versions
  dynamic "rule" {
    for_each = var.enable_versioning && var.noncurrent_version_expiration_days > 0 ? [1] : []
    content {
      id     = "expire-old-versions"
      status = "Enabled"

      filter {}

      noncurrent_version_expiration {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }
  }

  # Abort incomplete multipart uploads
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
}

# CORS configuration for web access
resource "aws_s3_bucket_cors_configuration" "media" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = var.cors_allowed_headers
    allowed_methods = var.cors_allowed_methods
    allowed_origins = var.cors_allowed_origins
    expose_headers  = var.cors_expose_headers
    max_age_seconds = var.cors_max_age_seconds
  }
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "media" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = aws_s3_bucket.media.id
  policy = var.bucket_policy
}

# Default bucket policy to enforce SSL/TLS
resource "aws_s3_bucket_policy" "enforce_ssl" {
  count  = var.bucket_policy == null && var.enforce_ssl ? 1 : 0
  bucket = aws_s3_bucket.media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.media.arn,
          "${aws_s3_bucket.media.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
