resource "aws_lb" "lb" {
    name               = "wsc2024-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
    
    tags = {
        Name = "wsc2024-alb"
    }
}

resource "aws_alb_listener" "lb" {
    load_balancer_arn = aws_lb.lb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
        type             = "forward"

        forward {
            target_group {
                arn = aws_alb_target_group.tg1.arn
            }
        }
    }
}