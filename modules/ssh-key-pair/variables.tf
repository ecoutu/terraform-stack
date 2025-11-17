variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "public_key" {
  description = "SSH public key material"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the key pair"
  type        = map(string)
  default     = {}
}
