# Route53 Hosted Zones Module

This module creates AWS Route53 hosted zones for DNS management.

## Features

- Public hosted zone for internet-accessible DNS records
- Private hosted zone for internal VPC DNS resolution
- Flexible configuration to create either or both zones
- Comprehensive outputs for zone IDs and name servers

## Usage

```hcl
module "route53" {
  source = "./modules/route53"

  domain_name         = "example.com"
  create_public_zone  = true
  create_private_zone = true
  vpc_id              = module.vpc.vpc_id

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

## Examples

### Public Zone Only
```hcl
module "route53_public" {
  source = "./modules/route53"

  domain_name        = "example.com"
  create_public_zone = true

  tags = {
    Environment = "production"
  }
}
```

### Private Zone Only
```hcl
module "route53_private" {
  source = "./modules/route53"

  domain_name          = "internal.example.com"
  create_public_zone   = false
  create_private_zone  = true
  vpc_id               = "vpc-123456"

  tags = {
    Environment = "production"
  }
}
```

### Both Public and Private Zones
```hcl
module "route53" {
  source = "./modules/route53"

  domain_name         = "example.com"
  create_public_zone  = true
  create_private_zone = true
  vpc_id              = module.vpc.vpc_id

  tags = {
    Environment = "production"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| domain_name | The domain name for the hosted zone | string | - | yes |
| create_public_zone | Create a public hosted zone | bool | true | no |
| create_private_zone | Create a private hosted zone | bool | false | no |
| vpc_id | VPC ID for private hosted zone | string | null | no* |
| tags | Tags to apply to hosted zones | map(string) | {} | no |
| dns_records | Map of DNS records to create | map(object) | {} | no |

*Required if `create_private_zone` is `true`

## Outputs

| Name | Description |
|------|-------------|
| public_zone_id | The hosted zone ID of the public zone |
| public_name_servers | The name servers for the public hosted zone |
| private_zone_id | The hosted zone ID of the private zone |
| private_name_servers | The name servers for the private hosted zone |
| domain_name | The domain name of the hosted zones |
| public_record_fqdns | Map of public DNS record FQDNs |
| private_record_fqdns | Map of private DNS record FQDNs |

## Notes

### Public Zone
- Creates a public hosted zone accessible from the internet
- Returns name servers that need to be configured with your domain registrar
- Supports standard DNS record types (A, AAAA, CNAME, MX, TXT, etc.)

### Private Zone
- Creates a private hosted zone associated with a VPC
- Only accessible from within the associated VPC
- Ideal for internal service discovery and private DNS resolution
- Requires a VPC ID to be specified

### DNS Delegation
After creating a public hosted zone, you must:
1. Note the name servers from `public_name_servers` output
2. Update your domain registrar's name server configuration
3. Wait for DNS propagation (typically 24-48 hours)

## Example DNS Records

After creating the zones, you can add DNS records:

```hcl
# Public A record
resource "aws_route53_record" "www" {
  zone_id = module.route53.public_zone_id
  name    = "www.example.com"
  type    = "A"
  ttl     = 300
  records = ["203.0.113.1"]
}

# Private A record
resource "aws_route53_record" "internal" {
  zone_id = module.route53.private_zone_id
  name    = "db.internal.example.com"
  type    = "A"
  ttl     = 300
  records = ["10.0.1.100"]
}
```
