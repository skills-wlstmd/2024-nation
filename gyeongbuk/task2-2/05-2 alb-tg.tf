resource "aws_alb_target_group" "lb" {
  name     = "wsi-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  deregistration_delay = 0

  health_check {
    path = "/healthcheck"
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

resource "aws_alb_target_group_attachment" "lb-1" {
  target_group_arn = aws_alb_target_group.lb.arn
  target_id        = aws_instance.app_1.id
  port             = 80
}

resource "aws_alb_target_group_attachment" "lb-2" {
  target_group_arn = aws_alb_target_group.lb.arn
  target_id        = aws_instance.app_2.id
  port             = 80
}