resource "aws_ecr_repository" "gwangju-cicd-ecr" {
  name = "gwangju-repo"
  
  tags = {
      Name = "gwangju-repo"
  } 
}