# Input variables for your Terraform configuration

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "my-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

# GitHub OIDC Configuration
variable "github_org" {
  description = "GitHub organization name"
  type        = string
  default     = "ecoutu"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "terraform-stack"
}

variable "github_branches" {
  description = "List of GitHub branches allowed to assume the role"
  type        = list(string)
  default     = ["main", "develop"]
}

variable "github_token" {
  description = "GitHub personal access token for managing repository secrets (leave empty to skip)"
  type        = string
  sensitive   = true
  default     = ""
}

# Terraform Backend Configuration
variable "terraform_state_bucket" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = ""
}

variable "enable_remote_state" {
  description = "Enable remote state backend (S3 + DynamoDB)"
  type        = bool
  default     = false
}

# GitHub Secrets and Variables
variable "github_secrets" {
  description = "Additional GitHub Actions secrets to set in the repository"
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "github_variables" {
  description = "Additional GitHub Actions variables to set in the repository"
  type        = map(string)
  default     = {}
}

variable "minikube_instance_type" {
  description = "Instance type to use for the minikube EC2 instance"
  type        = string
  default     = "t3.small"
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to development instances (override to restrict access). Defaults to 0.0.0.0/0 to preserve existing behavior but should be tightened in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_k8s_api_cidr_blocks" {
  description = "List of CIDR blocks allowed to access Kubernetes API Server (override to restrict access). Defaults to 0.0.0.0/0 to preserve existing behavior but should be tightened in production."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Domain name for Route53 hosted zones"
  type        = string
  default     = "linklayer.ca"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instances and Packer-built AMIs"
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) [A-Za-z0-9+/]+[=]{0,3}( .+)?$", var.ssh_public_key))
    error_message = "The ssh_public_key must be a valid SSH public key (ssh-rsa, ssh-ed25519, or ecdsa format)."
  }
}

