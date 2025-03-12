resource "aws_lb" "lb" {
  name               = "wsi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "wsi-alb"
  }
}

resource "aws_alb_listener" "lb" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.lb.arn
    type             = "forward"

    fixed_response {
      content_type = "text/plain"
      message_body = "404 Page Error"
      status_code  = "404"
    }
  }
}