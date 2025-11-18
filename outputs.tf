# Output values from your Terraform configuration

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ids" {
  description = "IDs of NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_ips" {
  description = "Public IPs of NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "availability_zones" {
  description = "List of availability zones used"
  value       = module.vpc.availability_zones
}

# IAM User Outputs
output "user_ecoutu_arn" {
  description = "ARN of IAM user ecoutu"
  value       = module.iam.user_arn
}

output "user_ecoutu_name" {
  description = "Name of IAM user ecoutu"
  value       = module.iam.user_name
}

output "user_ecoutu_access_key_id" {
  description = "Access key ID for user ecoutu"
  value       = module.iam.user_access_key_id
  sensitive   = true
}

output "user_ecoutu_access_key_secret" {
  description = "Access key secret for user ecoutu"
  value       = module.iam.user_access_key_secret
  sensitive   = true
}

# IAM Role Outputs
output "admin_role_arn" {
  description = "ARN of the administrator role"
  value       = module.iam.admin_role_arn
}

output "admin_role_name" {
  description = "Name of the administrator role"
  value       = module.iam.admin_role_name
}

output "admin_role_instance_profile_arn" {
  description = "ARN of the administrator role instance profile"
  value       = module.iam.admin_instance_profile_arn
}

output "admin_role_instance_profile_name" {
  description = "Name of the administrator role instance profile"
  value       = module.iam.admin_instance_profile_name
}

# Account Alias Output
output "account_alias" {
  description = "AWS account alias for console sign-in"
  value       = module.iam.account_alias
}

# GitHub Actions OIDC Outputs
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role"
  value       = module.github_actions_role.role_arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions OIDC role"
  value       = module.github_actions_role.role_name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github_actions_role.oidc_provider_arn
}

# GitHub Secrets Management Outputs
output "github_secrets_configured" {
  description = "Status of GitHub secrets configuration"
  value       = "GitHub secrets configured for ${var.github_org}/${var.github_repo}"
  sensitive   = true
}

output "github_secrets_list" {
  description = "List of secrets configured in GitHub"
  value       = module.github_secrets.secrets_configured
  sensitive   = true
}

output "github_variables_list" {
  description = "List of variables configured in GitHub"
  value       = module.github_secrets.variables_configured
  sensitive   = true
}

# Terraform Backend Outputs
output "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  value       = var.enable_remote_state ? module.terraform_backend[0].s3_bucket_id : "Not configured"
}

output "terraform_state_lock_table" {
  description = "DynamoDB table name for state locking"
  value       = var.enable_remote_state ? module.terraform_backend[0].dynamodb_table_name : "Not configured"
}

output "backend_config" {
  description = "Backend configuration for terraform block"
  value       = var.enable_remote_state ? module.terraform_backend[0].backend_config : null
  sensitive   = false
}

# Minikube Instance Outputs
output "minikube_instance_id" {
  description = "ID of the minikube EC2 instance"
  value       = module.minikube.instance_id
}

output "minikube_public_ip" {
  description = "Public IP address of the minikube instance"
  value       = module.minikube.public_ip
}

output "minikube_private_ip" {
  description = "Private IP address of the minikube instance"
  value       = module.minikube.private_ip
}

output "minikube_public_dns" {
  description = "Public DNS name of the minikube instance"
  value       = module.minikube.public_dns
}

output "minikube_security_group_id" {
  description = "Security group ID attached to the minikube instance"
  value       = module.minikube.security_group_id
}

output "minikube_ssh_command" {
  description = "SSH command to connect to the minikube instance"
  value       = "ssh -i ~/.ssh/id_rsa ecoutu@${module.minikube.public_ip}"
}

# Route53 Outputs
output "route53_public_zone_id" {
  description = "The hosted zone ID of the public Route53 zone"
  value       = module.route53.public_zone_id
}

output "route53_public_name_servers" {
  description = "The name servers for the public hosted zone (configure these with your domain registrar)"
  value       = module.route53.public_name_servers
}

output "route53_private_zone_id" {
  description = "The hosted zone ID of the private Route53 zone"
  value       = module.route53.private_zone_id
}

output "route53_domain_name" {
  description = "The domain name of the Route53 hosted zones"
  value       = module.route53.domain_name
}

output "route53_public_record_fqdns" {
  description = "Map of public DNS record FQDNs"
  value       = module.route53.public_record_fqdns
}

output "route53_private_record_fqdns" {
  description = "Map of private DNS record FQDNs"
  value       = module.route53.private_record_fqdns
}

output "minikube_public_fqdn" {
  description = "The public fully qualified domain name for the minikube instance"
  value       = module.route53.public_record_fqdns["minikube_public"]
}

output "minikube_private_fqdn" {
  description = "The private fully qualified domain name for the minikube instance"
  value       = module.route53.private_record_fqdns["minikube_private"]
}
