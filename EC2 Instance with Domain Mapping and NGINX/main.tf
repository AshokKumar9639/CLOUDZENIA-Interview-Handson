terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -------- VPC & Networking --------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = { Name = "ec2-nginx-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "ec2-nginx-igw" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = { Name = "public-a" }
}
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = { Name = "public-b" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = { Name = "private-a" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = { Name = "private-b" }
}

data "aws_availability_zones" "available" {}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# -------- Security Groups --------
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "Allow HTTP for redirect (ALB listener for 80 -> redirect)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "alb-sg" }
}

resource "aws_security_group" "instance_sg" {
  name   = "instance-sg"
  vpc_id = aws_vpc.main.id

  # Allow ALB to reach instances on ports 80 and 8080
  ingress {
    description = "From ALB on 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  ingress {
    description = "From ALB on 8080 (docker backend)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH from your IP (change 1.2.3.4/32)
  ingress {
    description = "SSH from admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace with your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "instance-sg" }
}

# -------- ALB --------
resource "aws_lb" "app_alb" {
  name               = "ec2-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = { Name = "ec2-app-alb" }
}

# Target groups: one for instance (nginx on port 80) and one for docker (8080)
resource "aws_lb_target_group" "tg_instance" {
  name     = "tg-instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "tg_docker" {
  name     = "tg-docker"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# HTTPS listener (requires ACM cert)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No host matched"
      status_code  = "404"
    }
  }
}

# HTTP listener that redirects to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      protocol = "HTTPS"
      port     = "443"
      status_code = "HTTP_301"
    }
  }
}

# Host-based rules for the two domain names to route to different target groups
resource "aws_lb_listener_rule" "rule_instance" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_instance.arn
  }
  condition {
    host_header {
      values = ["ec2-alb-instance.${var.domain_name}"]
    }
  }
}

resource "aws_lb_listener_rule" "rule_docker" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_docker.arn
  }
  condition {
    host_header {
      values = ["ec2-alb-docker.${var.domain_name}"]
    }
  }
}

# -------- EC2 Instances (2) with EIP attached --------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  ami_to_use = coalesce(var.ami_id, data.aws_ami.amazon_linux.id)
}

resource "aws_instance" "app" {
  count                     = 2
  ami                       = local.ami_to_use
  instance_type             = var.instance_type
  subnet_id                 = aws_subnet.public_a.id
  vpc_security_group_ids    = [aws_security_group.instance_sg.id]
  key_name                  = var.key_name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    domain_name = var.domain_name,
    host_eip    = "EIP_PLACEHOLDER" # replaced later by instance public ip; certbot may need manual steps
  })

  tags = {
    Name = "ec2-instance-${count.index + 1}"
  }
}

# Elastic IPs for instances
resource "aws_eip" "instance_eip" {
  count = 2
  instance = aws_instance.app[count.index].id
  vpc = true
  tags = { Name = "ec2-eip-${count.index+1}" }
}

# Register instances with target groups:
resource "aws_lb_target_group_attachment" "attach_instance" {
  count = 2
  target_group_arn = aws_lb_target_group.tg_instance.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach_docker" {
  count = 2
  target_group_arn = aws_lb_target_group.tg_docker.arn
  target_id        = aws_instance.app[count.index].id
  port             = 8080
}

# -------- Route53 records --------
# ALB DNS -> alias records for the two ALB hostnames
resource "aws_route53_record" "alb_docker" {
  zone_id = var.hosted_zone_id
  name    = "ec2-alb-docker.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "alb_instance" {
  zone_id = var.hosted_zone_id
  name    = "ec2-alb-instance.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

# Direct domain names pointing to instance EIPs
resource "aws_route53_record" "instance_records" {
  count   = 2
  zone_id = var.hosted_zone_id
  name    = element(["ec2-instance.${var.domain_name}", "ec2-docker.${var.domain_name}"], count.index)
  type    = "A"
  ttl     = 300
  records = [aws_eip.instance_eip[count.index].public_ip]
}

# -------- Outputs --------
output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
output "instance_eips" {
  value = [for e in aws_eip.instance_eip : e.public_ip]
}
output "instance_public_ips" {
  value = [for i in aws_instance.app : i.public_ip]
}
