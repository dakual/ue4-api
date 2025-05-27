resource "aws_cognito_user_pool" "main" {
  name = local.var.project_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "name"
    required            = true
  }
  
  schema {
    attribute_data_type = "String"
    mutable             = false
    name                = "email"
    required            = true
  }

  email_configuration {
    email_sending_account = local.var.domain.enabled ? "DEVELOPER" : "COGNITO_DEFAULT"
    from_email_address    = local.var.domain.enabled ? "${local.var.cognito.email_from}@${aws_ses_domain_identity.main[0].domain}" : ""
    source_arn            = local.var.domain.enabled ? aws_ses_domain_identity.main[0].arn : ""
  }

  verification_message_template {
    default_email_option  = "CONFIRM_WITH_CODE"
    email_subject         = local.var.cognito.email_subject
    email_message         = local.var.cognito.email_message
  }

  password_policy {
    minimum_length    = local.var.cognito.password_policy.minimum_length
    require_lowercase = local.var.cognito.password_policy.require_lowercase
    require_numbers   = local.var.cognito.password_policy.require_numbers
    require_symbols   = local.var.cognito.password_policy.require_symbols
    require_uppercase = local.var.cognito.password_policy.require_uppercase
  }

  lifecycle {
    ignore_changes = [
      schema
    ]
  }

  depends_on = [ 
    aws_acm_certificate_validation.main, 
    cloudflare_origin_ca_certificate.main 
  ]
}

resource "aws_cognito_user_pool_client" "main" {
  name = "client"
  allowed_oauth_flows_user_pool_client = true
  generate_secret      = false
  allowed_oauth_scopes = ["aws.cognito.signin.user.admin", "email", "openid", "profile"]
  allowed_oauth_flows  = ["implicit", "code"]
  explicit_auth_flows  = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
  supported_identity_providers = ["COGNITO"]
  user_pool_id  = aws_cognito_user_pool.main.id
  callback_urls = ["http://localhost"]
  logout_urls   = ["http://localhost"]
}

