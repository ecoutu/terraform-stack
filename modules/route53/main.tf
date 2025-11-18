resource "aws_route53_zone" "public" {
  count = var.create_public_zone ? 1 : 0

  name = var.domain_name

  tags = merge(
    var.tags,
    {
      Name = "${var.domain_name}-public"
      Type = "Public"
    }
  )
}

resource "aws_route53_zone" "private" {
  count = var.create_private_zone ? 1 : 0

  name = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.domain_name}-private"
      Type = "Private"
    }
  )
}

# DNS Records
resource "aws_route53_record" "public" {
  for_each = { for k, v in var.dns_records : k => v if v.zone == "public" && var.create_public_zone }

  zone_id = aws_route53_zone.public[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}

resource "aws_route53_record" "private" {
  for_each = { for k, v in var.dns_records : k => v if v.zone == "private" && var.create_private_zone }

  zone_id = aws_route53_zone.private[0].zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.records
}
