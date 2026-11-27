# Hosted zone. After the first apply, copy the name servers from the output
# into Namecheap → Domain → Nameservers → Custom DNS.
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# --- ACM certificate (apex + www), validated through Route 53 ---

resource "aws_acm_certificate" "site" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.site.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id         = aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 300
  allow_overwrite = true
}

# Waits until the certificate is ISSUED — only works once Namecheap points to Route 53.
resource "aws_acm_certificate_validation" "site" {
  certificate_arn         = aws_acm_certificate.site.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# --- Alias records → CloudFront (IPv4 + IPv6, apex + www) ---

locals {
  site_hosts   = toset([var.domain_name, "www.${var.domain_name}"])
  record_types = toset(["A", "AAAA"])
  alias_records = {
    for pair in setproduct(local.site_hosts, local.record_types) :
    "${pair[0]}-${pair[1]}" => { name = pair[0], type = pair[1] }
  }
}

resource "aws_route53_record" "site" {
  for_each = local.alias_records

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.site.domain_name
    zone_id                = aws_cloudfront_distribution.site.hosted_zone_id
    evaluate_target_health = false
  }
}
