# S3 Bucket Module

Terraform module for creating an S3 bucket with best practices for security, lifecycle management, and cost optimization.

## Features

- **Security**: Server-side encryption, public access blocking, SSL enforcement
- **Versioning**: Optional versioning for data protection
- **Lifecycle Management**: Intelligent-Tiering, Standard-IA, Glacier transitions
- **CORS**: Optional CORS configuration for web access
- **Cost Optimization**: Lifecycle policies to automatically transition objects to cheaper storage classes

## Usage

### Basic Usage

```hcl
module "media_bucket" {
  source = "./modules/s3-bucket"

  bucket_name = "my-media-storage"

  tags = {
    Environment = "production"
    Purpose     = "Media Storage"
  }
}
```

### With Intelligent-Tiering

```hcl
module "media_bucket" {
  source = "./modules/s3-bucket"

  bucket_name                = "my-media-storage"
  enable_lifecycle_rules     = true
  enable_intelligent_tiering = true

  tags = {
    Environment = "production"
  }
}
```

### With Custom Lifecycle Policies

```hcl
module "media_bucket" {
  source = "./modules/s3-bucket"

  bucket_name                = "my-media-storage"
  enable_versioning          = true
  enable_lifecycle_rules     = true
  transition_to_ia_days      = 30
  transition_to_glacier_days = 90

  tags = {
    Environment = "production"
  }
}
```

### With CORS for Web Access

```hcl
module "media_bucket" {
  source = "./modules/s3-bucket"

  bucket_name    = "my-media-storage"
  enable_cors    = true
  cors_allowed_origins = ["https://example.com"]
  cors_allowed_methods = ["GET", "HEAD"]

  tags = {
    Environment = "production"
  }
}
```

### With KMS Encryption

```hcl
module "media_bucket" {
  source = "./modules/s3-bucket"

  bucket_name        = "my-media-storage"
  sse_algorithm      = "aws:kms"
  kms_master_key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

  tags = {
    Environment = "production"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Resources

| Name | Type |
|------|------|
| aws_s3_bucket.media | resource |
| aws_s3_bucket_versioning.media | resource |
| aws_s3_bucket_server_side_encryption_configuration.media | resource |
| aws_s3_bucket_public_access_block.media | resource |
| aws_s3_bucket_lifecycle_configuration.media | resource |
| aws_s3_bucket_cors_configuration.media | resource |
| aws_s3_bucket_policy.media | resource |
| aws_s3_bucket_policy.enforce_ssl | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bucket_name | Name of the S3 bucket | `string` | n/a | yes |
| enable_versioning | Enable versioning for the bucket | `bool` | `false` | no |
| sse_algorithm | Server-side encryption algorithm (AES256 or aws:kms) | `string` | `"AES256"` | no |
| kms_master_key_id | KMS key ID for encryption (required if sse_algorithm is aws:kms) | `string` | `null` | no |
| block_public_access | Block all public access to the bucket | `bool` | `true` | no |
| enable_lifecycle_rules | Enable lifecycle rules for cost optimization | `bool` | `true` | no |
| enable_intelligent_tiering | Enable automatic transition to Intelligent-Tiering storage class | `bool` | `false` | no |
| transition_to_ia_days | Number of days before transitioning to Standard-IA (0 to disable) | `number` | `0` | no |
| transition_to_glacier_days | Number of days before transitioning to Glacier (0 to disable) | `number` | `0` | no |
| noncurrent_version_expiration_days | Number of days to retain old versions (requires versioning enabled) | `number` | `90` | no |
| abort_incomplete_multipart_upload_days | Number of days after which to abort incomplete multipart uploads | `number` | `7` | no |
| enable_cors | Enable CORS configuration for web access | `bool` | `false` | no |
| cors_allowed_headers | List of allowed headers for CORS | `list(string)` | `["*"]` | no |
| cors_allowed_methods | List of allowed HTTP methods for CORS | `list(string)` | `["GET", "HEAD"]` | no |
| cors_allowed_origins | List of allowed origins for CORS | `list(string)` | `["*"]` | no |
| cors_expose_headers | List of headers to expose in CORS responses | `list(string)` | `[]` | no |
| cors_max_age_seconds | Time in seconds that browser can cache the CORS response | `number` | `3600` | no |
| bucket_policy | Custom bucket policy JSON (overrides enforce_ssl if provided) | `string` | `null` | no |
| enforce_ssl | Enforce SSL/TLS for all bucket access | `bool` | `true` | no |
| tags | Tags to apply to the bucket | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The ID (name) of the bucket |
| bucket_arn | The ARN of the bucket |
| bucket_domain_name | The domain name of the bucket |
| bucket_regional_domain_name | The regional domain name of the bucket |
| bucket_region | The AWS region this bucket resides in |

## Storage Classes and Cost Considerations

### Storage Classes

- **Standard**: Default storage class, optimized for frequently accessed data
- **Intelligent-Tiering**: Automatically moves objects between access tiers based on usage patterns
- **Standard-IA**: Infrequent Access, lower cost for data accessed less frequently
- **Glacier Flexible Retrieval**: Archive storage with retrieval times from minutes to hours

### Cost Optimization Recommendations

For media storage workloads:

1. **Active Media**: Use Standard storage for recently added content
2. **Catalog Media**: Enable Intelligent-Tiering to automatically optimize costs
3. **Archive Media**: Transition old content to Glacier after 90+ days

### Example Cost Comparison (per TB/month in us-east-1)

- Standard: ~$23
- Intelligent-Tiering: ~$23 (frequently accessed), ~$12.50 (infrequent)
- Standard-IA: ~$12.50
- Glacier Flexible Retrieval: ~$3.60

## Security Best Practices

This module implements several security best practices:

1. **Encryption at Rest**: All data is encrypted using AES256 or KMS
2. **Encryption in Transit**: SSL/TLS is enforced for all bucket access
3. **Public Access Blocking**: Public access is blocked by default
4. **Versioning**: Optional versioning for data protection and recovery
5. **Lifecycle Policies**: Automatic cleanup of incomplete uploads

## Examples

See the [examples](../../examples/s3-bucket/) directory for complete examples.

## License

This module is licensed under the MIT License.
