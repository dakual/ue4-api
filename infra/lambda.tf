resource "aws_iam_role" "lambda" {
  name = "api-v1-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda" {
  name   = "api-v1-lambda-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:*",
          "cognito-idp:*",
          "dynamodb:*"
        ],
        Effect : "Allow",
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}



data "archive_file" "app" {
  for_each = tomap(local.var.endpoints)

  type        = "zip"
  source_dir  = "${path.module}/api-endpoints/${each.key}"
  output_path = "${path.module}/temp/${each.key}.zip"
}

resource "aws_lambda_function" "main" {
  for_each = tomap(local.var.endpoints)

  function_name     = "${each.key}"
  filename          = "${path.module}/temp/${each.key}.zip"
  source_code_hash  = data.archive_file.app[each.key].output_base64sha256
  timeout           = 10
  handler           = "app.lambda_handler"
  runtime           = "python3.9"
  role              = aws_iam_role.lambda.arn

  environment {
    variables = {
      DDB_USER_TABLE = aws_dynamodb_table.user.id
      USER_POOL_ID   = aws_cognito_user_pool.main.id
      CLIENT_ID      = aws_cognito_user_pool_client.main.id
      CLIENT_SECRET  = aws_cognito_user_pool_client.main.client_secret
    }
  }

  depends_on = [
    aws_cognito_user_pool.main,
    aws_cognito_user_pool_client.main
  ]
}

resource "aws_lambda_permission" "apigw" {
  for_each = tomap(local.var.endpoints)

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.main.execution_arn}/*"
}
