data "aws_route53_zone" "domain" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  name = local.var.domain.name
  private_zone = false
}


resource "aws_api_gateway_domain_name" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  domain_name              = "${local.var.domain.subdomain}.${local.var.domain.name}"
  regional_certificate_arn = aws_acm_certificate_validation.main[0].certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
}

resource "aws_route53_record" "api" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  name    = aws_api_gateway_domain_name.main[0].domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.domain[0].id

  alias {
    evaluate_target_health = true
    name                   = aws_api_gateway_domain_name.main[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.main[0].regional_zone_id
  }
}

resource "aws_route53_record" "acm" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.main[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.domain[0].zone_id
  ttl             = 60
}

resource "aws_acm_certificate" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  domain_name       = "${local.var.domain.subdomain}.${local.var.domain.name}"
  validation_method = "DNS"
  subject_alternative_names = ["${local.var.domain.subdomain}.${local.var.domain.name}"]
}

resource "aws_acm_certificate_validation" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  certificate_arn         = aws_acm_certificate.main[0].arn
  validation_record_fqdns = [for record in aws_route53_record.acm : record.fqdn]
}

resource "aws_route53_record" "ses" {
  count   = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0

  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = "_amazonses.${aws_ses_domain_identity.main[0].id}"
  type    = "TXT"
  ttl     = "60"
  records = [aws_ses_domain_identity.main[0].verification_token]
}


resource "aws_route53_record" "ses_dkim" {
  count   = local.var.domain.enabled && local.var.domain.provide == "aws" ? 3 : 0 

  zone_id = data.aws_route53_zone.domain[0].id
  name    = "${element(aws_ses_domain_dkim.main[0].dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "60"
  records = [
    "${element(aws_ses_domain_dkim.main[0].dkim_tokens, count.index)}.dkim.amazonses.com"
  ]
}


resource "aws_route53_record" "ses-spf" {
  count   = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0 

  zone_id = data.aws_route53_zone.domain[0].id
  name    = "mail.${local.var.domain.name}"
  type    = "TXT"
  ttl     = "60"

  records = [
    "v=spf1 include:amazonses.com ~all",
  ]
}

resource "aws_route53_record" "ses-dmarc" {
  count   = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0 

  zone_id = data.aws_route53_zone.domain[0].id
  name    = "_dmarc.${local.var.domain.name}"
  type    = "TXT"
  ttl     = "60"

  records = [
    "v=DMARC1; p=none;",
  ]
}

resource "aws_route53_record" "ses-mx" {
  count   = local.var.domain.enabled && local.var.domain.provide == "aws" ? 1 : 0 

  zone_id = data.aws_route53_zone.domain[0].zone_id
  name    = "_email.${local.var.domain.name}"
  type    = "MX"
  ttl     = "60"

  records = [
    "10 feedback-smtp.${local.var.region}.amazonses.com"
    ]
}
