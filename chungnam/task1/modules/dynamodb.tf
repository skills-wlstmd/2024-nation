resource "aws_dynamodb_table" "order-table" {
  name           = "order"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "order"
  }
}