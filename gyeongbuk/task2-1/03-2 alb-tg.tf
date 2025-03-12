resource "aws_alb_target_group" "lb" {
  name     = "wsi-alb-tg"
  port     = 80
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.main.id
  deregistration_delay = 0

  health_check {
    path = "/"
    port = 80
    timeout = 2
    interval = 5
    unhealthy_threshold = 2
    healthy_threshold = 2
  }
  
  tags = {
    Name = "wsi-alb-tg"
  }
}