resource "aws_dynamodb_table" "dynamodb" {
  name           = "gm-db"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "PK"
  range_key      = "SK"
  
  attribute {
    name = "PK"
    type = "S"
  }
  
  attribute {
    name = "SK"
    type = "S"
  
  }
  
  tags = {
    Name = "gm-db"
  }
}