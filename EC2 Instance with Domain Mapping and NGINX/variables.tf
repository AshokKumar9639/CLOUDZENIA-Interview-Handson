variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" { default = "10.0.1.0/24" }
variable "public_subnet_cidr_2" { default = "10.0.2.0/24" }
variable "private_subnet_cidr_1" { default = "10.0.11.0/24" }
variable "private_subnet_cidr_2" { default = "10.0.12.0/24" }

variable "instance_type" { default = "t3.micro" }
variable "key_name" { type = string }

# Replace example.com with your domain or pass at terraform apply
variable "domain_name" {
  type = string
  description = "Your domain name (example.com)"
}

variable "hosted_zone_id" {
  type = string
  description = "Route53 Hosted Zone ID for the domain"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for ALB HTTPS listener (request or import beforehand)"
}

variable "ami_id" {
  type    = string
  default = "" # set to a proper Linux AMI for your region (e.g. Amazon Linux 2)
}
