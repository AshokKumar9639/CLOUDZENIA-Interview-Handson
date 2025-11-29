module "vpc" {
  source = "./modules/vpc"
  name = var.name_prefix
  cidr_block = var.vpc_cidr
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets
  azs = var.azs
}

module "alb" {
  source = "./modules/alb"
  name = var.name_prefix
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  domain_name = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

# Store DB password in Secrets Manager
module "secrets" {
  source = "./modules/secrets"
  name = var.name_prefix
  username = var.db_username
  password = var.db_password
  db_name = "wordpress"
}

module "rds" {
  source = "./modules/rds"
  name = var.name_prefix
  engine = "mysql"
  instance_class = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name = "wordpress"
  username = var.db_username
  password = var.db_password
  backup_retention_days = var.db_backup_retention_days
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id = module.vpc.vpc_id
  ecs_security_group_id = "" # will be replaced below after ECS SG created
}

# ECS module - pass ALB target group ARNs and vpc/subnets
module "ecs" {
  source = "./modules/ecs"
  name = var.name_prefix
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  wordpress_tg_arn = module.alb.wordpress_tg
  micro_tg_arn = module.alb.micro_tg
  rds_secret_arn = aws_secretsmanager_secret_version.db_ver.secret_id != "" ? aws_secretsmanager_secret.db.id : module.secrets.rds_secret_arn
  microservice_ecr_repo = var.microservice_ecr_repo
  aws_region = var.aws_region
  alb_security_group_id = module.alb.alb_security_group_id
}
