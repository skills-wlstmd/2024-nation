resource "aws_alb_target_group" "tg1" {
    name     = "wsc2024-tg1"
    port     = 8080
    protocol = "HTTP"
    target_type = "ip"
    vpc_id   = aws_default_vpc.default.id

    health_check {
        path = "/healthcheck"
        port = 8080
        timeout = 2
        interval = 5
        unhealthy_threshold = 2
        healthy_threshold = 2
    }

    tags = {
        Name = "wsc2024-tg1"
    }
}

resource "aws_alb_target_group" "tg2" {
    name     = "wsc2024-tg2"
    port     = 8080
    protocol = "HTTP"
    target_type = "ip"
    vpc_id   = aws_default_vpc.default.id

    health_check {
        path = "/healthcheck"
        port = 8080
        timeout = 2
        interval = 5
        unhealthy_threshold = 2
        healthy_threshold = 2
    }

    tags = {
        Name = "wsc2024-tg2"
    }
}