module "usa" {
    source = "./modules"
    create_region = "us-east-1"
    providers = {
      aws = aws.usa
    }
}