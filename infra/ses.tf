resource "aws_ses_domain_identity" "main" {
  count  = local.var.domain.enabled ? 1 : 0

  domain = local.var.domain.name
}

resource "aws_ses_domain_dkim" "main" {
  count  = local.var.domain.enabled ? 1 : 0

  domain = aws_ses_domain_identity.main[0].domain
}

resource "aws_ses_domain_mail_from" "main" {
  count                  = local.var.domain.enabled ? 1 : 0

  domain                 = aws_ses_domain_identity.main[0].domain
  mail_from_domain       = "mail.${aws_ses_domain_identity.main[0].domain}"
  behavior_on_mx_failure = "UseDefaultValue"
}

resource "aws_ses_domain_identity_verification" "main" {
  count  = local.var.domain.enabled ? 1 : 0

  domain     = aws_ses_domain_identity.main[0].id
  depends_on = [
    aws_route53_record.ses,
    cloudflare_record.ses
  ]
}


