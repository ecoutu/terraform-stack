variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be between 3 and 63 characters, start and end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for the bucket"
  type        = bool
  default     = false
}

variable "sse_algorithm" {
  description = "Server-side encryption algorithm (AES256 or aws:kms)"
  type        = string
  default     = "AES256"

  validation {
    condition     = contains(["AES256", "aws:kms"], var.sse_algorithm)
    error_message = "SSE algorithm must be either 'AES256' or 'aws:kms'."
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for encryption (required if sse_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block all public access to the bucket"
  type        = bool
  default     = true
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules for cost optimization"
  type        = bool
  default     = true
}

variable "enable_intelligent_tiering" {
  description = "Enable automatic transition to Intelligent-Tiering storage class"
  type        = bool
  default     = false
}

variable "transition_to_ia_days" {
  description = "Number of days before transitioning to Standard-IA (0 to disable)"
  type        = number
  default     = 0
}

variable "transition_to_glacier_days" {
  description = "Number of days before transitioning to Glacier (0 to disable)"
  type        = number
  default     = 0
}

variable "noncurrent_version_expiration_days" {
  description = "Number of days to retain old versions (requires versioning enabled)"
  type        = number
  default     = 90
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which to abort incomplete multipart uploads"
  type        = number
  default     = 7
}

variable "enable_cors" {
  description = "Enable CORS configuration for web access"
  type        = bool
  default     = false
}

variable "cors_allowed_headers" {
  description = "List of allowed headers for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "List of allowed HTTP methods for CORS"
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS"
  type        = list(string)
  default     = ["*"]
}

variable "cors_expose_headers" {
  description = "List of headers to expose in CORS responses"
  type        = list(string)
  default     = []
}

variable "cors_max_age_seconds" {
  description = "Time in seconds that browser can cache the CORS response"
  type        = number
  default     = 3600
}

variable "bucket_policy" {
  description = "Custom bucket policy JSON (overrides enforce_ssl if provided)"
  type        = string
  default     = null
}

variable "enforce_ssl" {
  description = "Enforce SSL/TLS for all bucket access"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the bucket"
  type        = map(string)
  default     = {}
}
