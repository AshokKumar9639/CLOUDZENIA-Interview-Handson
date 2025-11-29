resource "aws_security_group" "alb_sg" {
  name = "${var.name}-alb-sg"
  vpc_id = var.vpc_id
  description = "Allow 443 only"
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # optional to block 80 or allow 80 to redirect
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false
}

# ACM certificate (DNS validation)
resource "aws_acm_certificate" "cert" {
  domain_name = var.domain_name
  validation_method = "DNS"
  subject_alternative_names = [
    "microservice.${var.domain_name}",
    "wordpress.${var.domain_name}"
  ]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation: record.fqdn]
}

# Target groups
resource "aws_lb_target_group" "wordpress_tg" {
  name        = "${var.name}-wordpress-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path = "/"
    matcher = "200-399"
    interval = 30
  }
}

resource "aws_lb_target_group" "micro_tg" {
  name        = "${var.name}-micro-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path = "/"
    matcher = "200-399"
    interval = 30
  }
}

# HTTPS listener using certificate
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not found"
      status_code  = "404"
    }
  }
}

# Optional redirect listener from HTTP -> HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listeners for path based routing - route /micro to microservice and host based for wordpress & microservice
resource "aws_lb_listener_rule" "micro_path" {
  listener_arn = aws_lb_listener.https.arn
  priority = 10
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.micro_tg.arn
  }
  condition {
    path_pattern {
      values = ["/micro*"]
    }
  }
}

# host-based rules for subdomains
resource "aws_lb_listener_rule" "wordpress_host" {
  listener_arn = aws_lb_listener.https.arn
  priority = 20
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wordpress_tg.arn
  }
  condition {
    host_header { values = ["wordpress.${var.domain_name}","${var.domain_name}"] }
  }
}

resource "aws_lb_listener_rule" "micro_host" {
  listener_arn = aws_lb_listener.https.arn
  priority = 30
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.micro_tg.arn
  }
  condition {
    host_header { values = ["microservice.${var.domain_name}"] }
  }
}
