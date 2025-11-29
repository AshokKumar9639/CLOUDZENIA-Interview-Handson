variable "aws_region" { 
    description = "AWS Region name"
    type = string,
    default = "us-east-1"
}
variable "name_prefix" {
    description = "Just a prefix of the name"
    type = string,
    default = "cloudzenia"
}

# VPC
variable "vpc_cidr" {
    description = "Defining VPC CIDR range"
    type = string,
    default = "10.0.0.0/16"
}

variable "public_subnets" {
    description = "Public subnets"
    type = list(string),
    default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnets" {
    description = "Private subnets"
    type = list(string),
    default = ["10.0.11.0/24","10.0.12.0/24"]
}

variable "azs" {
    description = "Availability zones"
    type = list(string),
    default = ["us-east-1a","us-east-1b"]
}

# Domain / Route53
variable "domain_name" {
    type = string
}
variable "hosted_zone_id" {
    type = string
}

# RDS
variable "db_username" {
    description = "DB username"
    type = string,
    default = "wpuser"
}

variable "db_password" {
    description = "DB password"
    type = string   # set in terraform.tfvars or use secrets manager manually
}

variable "db_instance_class" {
    description = "Database instance class"
    type = string,
    default = "db.t3.micro"
}

variable "db_allocated_storage" {
    description = "database allocation storage"
    type = number,
    default = 20
}

variable "db_backup_retention_days" {
    description = "Database backup retention in days"
    type = number,
    default = 7
}

# ECS / ECR
variable "microservice_ecr_repo" {
    description = "microservice ecr repo url"
    type = string,
    default = "microservice"
}

# Misc
variable "public_key_name" {
    description = "optional for SSH if needed"
    type = string,
    default = ""
}
