variable "name" {
  type = string
}

variable "engine" {
  type = string,
  default = "mysql"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "backup_retention_days" {
  type = number
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "ecs_security_group_id" {
  type = string
}
