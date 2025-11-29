output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
output "wordpress_url" {
  value = "https://${var.domain_name}"
}
output "microservice_url" {
  value = "https://microservice.${var.domain_name}"
}
output "rds_endpoint" { 
  value = module.rds.rds_endpoint
}
