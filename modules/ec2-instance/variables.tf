variable "subnet_ids" {
  description = "List of subnet IDs where the EC2 instance may be placed. The first subnet will be used."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "At least one subnet ID must be provided."
  }
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "name_prefix" {
  description = "Prefix used for naming resources"
  type        = string
}

variable "ami_name_filter" {
  description = "AMI name filter to select an AMI"
  type        = string
  default     = "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64*"
}

variable "ami_owner" {
  description = "AMI owner ID"
  type        = string
  default     = "099720109477" # Canonical
}

variable "ami_id" {
  description = "Specific AMI ID to use (overrides ami_name_filter and ami_owner)"
  type        = string
  default     = null
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "key_name" {
  description = "Name of the SSH key pair to attach to the instance"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = null
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IP address"
  type        = bool
  default     = true
}

variable "root_block_device_volume_size" {
  description = "Size of the root block device in GB"
  type        = number
  default     = 32
}

variable "root_block_device_volume_type" {
  description = "Type of root block device (gp2, gp3, io1, etc.)"
  type        = string
  default     = "gp3"
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
