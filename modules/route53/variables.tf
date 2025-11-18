variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "create_public_zone" {
  description = "Create a public hosted zone"
  type        = bool
  default     = true
}

variable "create_private_zone" {
  description = "Create a private hosted zone"
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "VPC ID for private hosted zone (required if create_private_zone is true)"
  type        = string
  default     = null

  validation {
    condition     = !var.create_private_zone || var.vpc_id != null
    error_message = "vpc_id must be provided when create_private_zone is true."
  }
}

variable "tags" {
  description = "Tags to apply to hosted zones"
  type        = map(string)
  default     = {}
}

variable "dns_records" {
  description = "Map of DNS records to create"
  type = map(object({
    name    = string
    type    = string
    ttl     = number
    records = list(string)
    zone    = string # "public" or "private"
  }))
  default = {}
}
