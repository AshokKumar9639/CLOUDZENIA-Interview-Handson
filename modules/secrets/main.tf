resource "aws_secretsmanager_secret" "db" {
  name = "${var.name}-rds-credentials"
  description = "RDS credentials for WordPress"
}

resource "aws_secretsmanager_secret_version" "db_ver" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.username
    password = var.password
    engine   = var.engine
    host     = var.host != "" ? var.host : ""
    port     = tostring(var.port)
    dbname   = var.db_name
  })
}
