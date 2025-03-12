resource "aws_ecr_repository" "ecr" {
    name = "wsc2024-repo"

    image_scanning_configuration {
        scan_on_push = true
    }
    
    tags = {
        Name = "wsc2024-repo"
    }
}