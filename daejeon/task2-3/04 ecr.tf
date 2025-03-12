resource "aws_ecr_repository" "ecr" {
  name = "wsi-ecr"
  
  tags = {
      Name = "wsi-ecr"
  } 
}