resource "aws_dynamodb_table" "dynamodb" {
    name = "wsi-table"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key = "name"
    
    attribute {
        name = "name"
        type = "S"
    }

    tags = {
        Name = "wsi-table"
    }
}