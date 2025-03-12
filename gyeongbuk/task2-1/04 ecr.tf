resource "aws_ecr_repository" "ecr" {
  name = "wsi-ecr"
  image_tag_mutability = "IMMUTABLE"

    tags = {
        Name = "wsi-ecr"
    }
}