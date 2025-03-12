resource "aws_alb_target_group" "token" {
  name     = "gm-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/healthcheck"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "gm-tg"
  }
}

resource "aws_alb_target_group_attachment" "token-1" {
  target_group_arn = aws_alb_target_group.token.arn
  target_id        = aws_instance.private-ec2-1.id
  port             = 5000
}