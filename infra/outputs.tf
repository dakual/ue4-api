output "api_base_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "api_domain" {
  value = local.var.domain.enabled ? "https://${local.var.domain.subdomain}.${local.var.domain.name}" : "None"
}

output "api_endpoints" {
  value = {
    for k, bd in aws_api_gateway_resource.main : k => bd.path
  }
}
