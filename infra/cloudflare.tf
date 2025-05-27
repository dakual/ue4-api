data "cloudflare_zone" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0
  name  = "dakual.com"
}

resource "cloudflare_record" "ses" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = "_amazonses.${aws_ses_domain_identity.main[0].id}"
  value   = aws_ses_domain_identity.main[0].verification_token
  type    = "TXT"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "ses_dkim" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 3 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = "${element(aws_ses_domain_dkim.main[0].dkim_tokens, count.index)}._domainkey"
  value   = "${element(aws_ses_domain_dkim.main[0].dkim_tokens, count.index)}.dkim.amazonses.com"
  type    = "CNAME"
  ttl     = 60
  proxied = false
}


resource "cloudflare_record" "ses-spf" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = "_email.${local.var.domain.name}"
  value   = "v=spf1 include:amazonses.com ~all"
  type    = "TXT"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "ses-dmarc" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = "_dmarc.${local.var.domain.name}"
  value   = "v=DMARC1; p=none;"
  type    = "TXT"
  ttl     = 60
  proxied = false
}

resource "cloudflare_record" "ses-mx" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = "mail.${local.var.domain.name}"
  value   = "feedback-smtp.${local.var.region}.amazonses.com"
  priority = 10
  type    = "MX"
  ttl     = 60
  proxied = false
}

resource "tls_private_key" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  algorithm = "RSA"
}

resource "tls_cert_request" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  private_key_pem = tls_private_key.main[0].private_key_pem

  subject {
    common_name  = local.var.domain.name
    organization = local.var.project_name
  }
}

resource "cloudflare_origin_ca_certificate" "main" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  csr                = tls_cert_request.main[0].cert_request_pem
  hostnames          = [local.var.domain.name, "${local.var.domain.subdomain}.${local.var.domain.name}"]
  request_type       = "origin-rsa"
  requested_validity = 5475
}

resource "aws_acm_certificate" "cert" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  private_key      = tls_private_key.main[0].private_key_pem
  certificate_body = cloudflare_origin_ca_certificate.main[0].certificate
}

resource "aws_api_gateway_domain_name" "main-cf" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  domain_name              = "${local.var.domain.subdomain}.${local.var.domain.name}"
  regional_certificate_arn = aws_acm_certificate.cert[0].arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "main-cf" {
  count = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main-cf[0].domain_name
}

resource "cloudflare_record" "api" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0

  zone_id = data.cloudflare_zone.main[0].id
  name    = aws_api_gateway_domain_name.main-cf[0].domain_name
  value   = aws_api_gateway_domain_name.main-cf[0].regional_domain_name
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_zone_settings_override" "main" {
  count   = local.var.domain.enabled && local.var.domain.provide == "cf" ? 1 : 0
  zone_id = data.cloudflare_zone.main[0].id

  settings {
    ssl = "full"
  }
}