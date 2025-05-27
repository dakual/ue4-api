resource "aws_dynamodb_table" "user" {
  name           = "user"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "UserEmail"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "UserEmail"
    type = "S"
  }
}