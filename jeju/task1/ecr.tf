resource "aws_ecr_repository" "customer" {
  name = "customer"

    tags = {
        Name = "customer"
    } 
}

resource "aws_ecr_repository" "product" {
  name = "product"

    tags = {
        Name = "product"
    } 
}

resource "aws_ecr_repository" "order" {
  name = "order"

    tags = {
        Name = "order"
    } 
}

output "customer-ecr" {
    value = aws_ecr_repository.customer.name
}

output "product-ecr" {
    value = aws_ecr_repository.product.name
}

output "order" {
    value = aws_ecr_repository.order.name
}