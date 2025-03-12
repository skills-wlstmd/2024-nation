resource "aws_ecs_cluster" "cluster" {
  name = "wsi-ecs"

  tags = {
    Name = "wsi-ecs"
  }
}
