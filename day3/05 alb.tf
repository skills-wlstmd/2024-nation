resource "aws_security_group" "alb" {
  name        = "apdev-ALB-SG"
  description = "apdev-ALB-SG"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "apdev-ALB-SG"
  }
}

resource "aws_lb" "alb" {
  name               = "apdev-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.app_a.id, aws_subnet.app_b.id]

  tags = {
    Name = "apdev-alb"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.employee.arn
        weight = 50
      }

      target_group {
        arn    = aws_lb_target_group.token.arn
        weight = 50
      }
    }
  }
}

resource "aws_lb_listener_rule" "employee" {
  listener_arn = aws_lb_listener.alb.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.employee.arn
  }

  condition {
    path_pattern {
      values = ["/v1/employee"]
    }
  }
}

resource "aws_lb_listener_rule" "token" {
  listener_arn = aws_lb_listener.alb.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.token.arn
  }

  condition {
    path_pattern {
      values = ["/v1/token"]
    }
  }
}

resource "aws_lb_target_group" "employee" {
  name        = "apdev-employee-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    port                = 8080
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    path                = "/healthcheck"
  }

  tags = {
    Name = "apdev-employee-tg"
  }
}

resource "aws_lb_target_group" "token" {
  name        = "apdev-token-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    port                = 8080
    interval            = 10
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    path                = "/healthcheck"
  }

  tags = {
    Name = "apdev-token-tg"
  }
}

# resource "aws_lb_target_group_attachment" "employee" {
#   target_group_arn = aws_lb_target_group.employee.arn
#   target_id        = aws_instance.app1.id
#   port             = 8080

#   depends_on       = [aws_instance.app1]
# }

# resource "aws_lb_target_group_attachment" "token" {
#   target_group_arn = aws_lb_target_group.token.arn
#   target_id        = aws_instance.app2.id
#   port             = 8080

#   depends_on       = [aws_instance.app2]
# }