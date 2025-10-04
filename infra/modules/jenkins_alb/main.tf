# Application Load Balancer
resource "aws_lb" "jenkins" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb"
    }
  )
}

# 目标组
resource "aws_lb_target_group" "jenkins" {
  name     = "${var.name_prefix}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5  # 增加失败阈值，给 Jenkins 更多启动时间
    timeout             = 10 # 增加超时时间
    interval            = 60 # 增加检查间隔，减少检查频率
    path                = var.health_check_path
    matcher             = "200,403,404"  # Jenkins 启动期间可能返回 404
  }

  deregistration_delay = 30

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tg"
    }
  )
}

# 注册目标
resource "aws_lb_target_group_attachment" "jenkins" {
  target_group_arn = aws_lb_target_group.jenkins.arn
  target_id        = var.target_id
  port             = 8080
}

# HTTPS 监听器（如果提供了证书）
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != "" ? 1 : 0
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins.arn
  }

  tags = var.tags
}

# HTTP 监听器
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.jenkins.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    # 如果有 HTTPS，重定向到 HTTPS
    type = var.certificate_arn != "" ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    target_group_arn = var.certificate_arn != "" ? null : aws_lb_target_group.jenkins.arn
  }

  tags = var.tags
}

