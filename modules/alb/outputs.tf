output "alb_arn" { value = aws_lb.alb.arn }

output "alb_dns_name" { value = aws_lb.alb.dns_name }

output "wordpress_tg" { value = aws_lb_target_group.wordpress_tg.arn }

output "micro_tg" { value = aws_lb_target_group.micro_tg.arn }
