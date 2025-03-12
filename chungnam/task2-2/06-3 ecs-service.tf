resource "aws_ecs_service" "svc" {
  name            = "wsc2024-svc"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = 1

  network_configuration {
    subnets = [ aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id ]
    security_groups = [ aws_security_group.ecs.id ]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.tg1.arn
    container_name   = "wsc2024-container"
    container_port   = 8080
  }
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}