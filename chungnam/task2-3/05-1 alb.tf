resource "aws_lb" "test" {
  name               = "gm-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = {
    Name = "gm-alb"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.token.arn
    type             = "forward"
  }
}