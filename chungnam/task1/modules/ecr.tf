data "aws_caller_identity" "customer" {}
resource "aws_ecr_repository" "ecr" {
  name = "customer-repo"
    tags = {
        Name = "customer-repo"
    } 
}
resource "aws_ecr_repository" "Product" {
  name = "product-repo"
    tags = {
        Name = "hrdkorea-ecr-repo"
    } 
}
resource "aws_ecr_repository" "order" {
  name = "order-repo"
    tags = {
        Name = "order-repo"
    } 
}