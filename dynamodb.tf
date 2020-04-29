resource aws_dynamodb_table this {
  name         = module.label.id
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "group"
  tags         = module.label.tags

  attribute {
    name = "group"
    type = "S"
  }

  # attribute {
  #   name = "owner"
  #   type = "S"
  # }

  # attribute {
  #   name = "expires"
  #   type = "N"
  # }
}
