variable "name" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "engine" {
  type = string,
  default = "mysql"
}

variable "host" {
  type = string,
  default = ""
}

variable "port" {
  type = number,
  default = 3306
}

variable "db_name" {
  type = string,
  default = "wordpress"
}
