data aws_route53_zone this {
  zone_id = var.route53_zone_id
}

resource aws_route53_record this {
  zone_id = var.route53_zone_id
  name    = aws_api_gateway_domain_name.this.domain_name
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.this.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.this.regional_zone_id
  }
}

resource aws_acm_certificate this {
  domain_name       = join(".", [var.stage, var.name, data.aws_route53_zone.this.name])
  validation_method = "DNS"

  tags = module.label.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource aws_acm_certificate_validation this {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [aws_route53_record.acm_validation.fqdn]
}

resource aws_route53_record acm_validation {
  name    = aws_acm_certificate.this.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.this.domain_validation_options.0.resource_record_type
  zone_id = data.aws_route53_zone.this.id
  records = [aws_acm_certificate.this.domain_validation_options.0.resource_record_value]
  ttl     = 60
}
