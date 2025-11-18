output "public_zone_id" {
  description = "The hosted zone ID of the public zone"
  value       = var.create_public_zone ? aws_route53_zone.public[0].zone_id : null
}

output "public_name_servers" {
  description = "The name servers for the public hosted zone"
  value       = var.create_public_zone ? aws_route53_zone.public[0].name_servers : []
}

output "private_zone_id" {
  description = "The hosted zone ID of the private zone"
  value       = var.create_private_zone ? aws_route53_zone.private[0].zone_id : null
}

output "private_name_servers" {
  description = "The name servers for the private hosted zone (for internal AWS use only; private zones use VPC DNS resolution)"
  value       = var.create_private_zone ? aws_route53_zone.private[0].name_servers : []
}

output "domain_name" {
  description = "The domain name of the hosted zones"
  value       = var.domain_name
}

output "public_record_fqdns" {
  description = "Map of public DNS record FQDNs"
  value       = { for k, v in aws_route53_record.public : k => v.fqdn }
}

output "private_record_fqdns" {
  description = "Map of private DNS record FQDNs"
  value       = { for k, v in aws_route53_record.private : k => v.fqdn }
}
