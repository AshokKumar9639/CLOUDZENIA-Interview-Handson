variable "name" { type = string }

variable "vpc_id" { type = string }

variable "alb_sg_id"        { type = string }

variable "private_subnet_ids" { type = list(string) }

variable "wordpress_tg_arn" { type = string }

variable "micro_tg_arn" { type = string }

variable "wp_db_name" { type = string, default = "wordpress" }

variable "rds_secret_arn" { type = string }

variable "microservice_ecr_repo" { type = string }

variable "microservice_ecr_repo_url" { type = string, default = "" }

variable "microservice_image" { type = string }

variable "aws_region" { type = string }

variable "alb_security_group_id" { type = string }
