# Subnet group
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags = { Name = "${var.name}-db-subnet-group" }
}

# Security group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Allow DB access from ECS"
  vpc_id      = var.vpc_id
}

# Allow ECS security group id list
resource "aws_security_group_rule" "allow_from_ecs" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = aws_security_group.rds.id
  source_security_group_id = var.ecs_security_group_id
}

resource "aws_db_instance" "this" {
  identifier              = "${var.name}-db"
  engine                  = var.engine
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  name                    = var.db_name
  username                = var.username
  password                = var.password
  skip_final_snapshot     = true
  backup_retention_period = var.backup_retention_days
  vpc_security_group_ids  = [aws_security_group.rds.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  publicly_accessible     = false
  multi_az                = false
}
