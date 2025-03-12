resource "aws_ecr_repository" "ecr" {
  name = "service"
  
  tags = {
      Name = "service"
  } 
}