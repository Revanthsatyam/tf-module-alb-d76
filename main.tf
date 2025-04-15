resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = var.internal
  load_balancer_type = var.load_balancer_type
  security_groups    = [aws_security_group.main.id]
  subnets            = var.subnets
  tags               = merge(local.tags, { Name = "${var.env}-alb" })
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = var.sg_port
  protocol          = var.internal ? "HTTP" : "HTTPS"
  ssl_policy        = var.internal ? null : "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.internal ? null : "arn:aws:acm:us-east-1:058264090525:certificate/83a2cdee-c12e-486d-b210-46fdc46cec73"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Error 404"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "frontend" {
  count             = var.internal ? 0 : 1
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_security_group" "main" {
  name   = var.internal ? "private-alb-sg" : "public-alb-sg"
  vpc_id = var.vpc_id
  tags   = merge(local.tags, { Name = var.internal ? "${var.env}-private-alb-sg" : "${var.env}-public-alb-sg" })

  ingress {
    description = "APP"
    from_port   = var.sg_port
    to_port     = var.sg_port
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "frontend" {
  count             = var.internal ? 0 : 1
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ingress
  security_group_id = aws_security_group.main.id
}