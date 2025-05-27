resource "aws_api_gateway_rest_api" "main" {
  name = local.var.project_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "main" {
  for_each = tomap(local.var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "main" {
  for_each = tomap(local.var.endpoints)

  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main[each.key].id
  http_method   = each.value.method

  authorization = each.value.auth == true ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = each.value.auth == true ? aws_api_gateway_authorizer.main.id : "NONE" 
}

resource "aws_api_gateway_integration" "main" {
  for_each = tomap(local.var.endpoints)

  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.main[each.key].id
  http_method             = aws_api_gateway_method.main[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main[each.key].invoke_arn
}

resource "aws_api_gateway_method_response" "main" {
  for_each = tomap(local.var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main[each.key].id
  http_method = aws_api_gateway_method.main[each.key].http_method
  status_code = "200"

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "main" {
  for_each = tomap(local.var.endpoints)

  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main[each.key].id
  http_method = aws_api_gateway_method.main[each.key].http_method
  status_code = aws_api_gateway_method_response.main[each.key].status_code

  //cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.main,
    aws_api_gateway_integration.main
  ]
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.main.body))
  }

  depends_on = [
    aws_api_gateway_integration.main
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = local.var.apigateway.stage
}

resource "aws_api_gateway_authorizer" "main" {
  name = "api_authorizer"
  rest_api_id = aws_api_gateway_rest_api.main.id
  type = "COGNITO_USER_POOLS"
  provider_arns = [aws_cognito_user_pool.main.arn]
}

