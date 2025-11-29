# ECS cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-ecs"
}

# ECR repository for microservice
resource "aws_ecr_repository" "micro" {
  name = var.microservice_ecr_repo
  image_tag_mutability = "MUTABLE"
}

# IAM role for task execution
data "aws_iam_policy_document" "task_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals { type = "Service"; identifiers = ["ecs-tasks.amazonaws.com"] }
  }
}

resource "aws_iam_role" "task_exec" {
  name = "${var.name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "task_exec_attach" {
  role = aws_iam_role.task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM policy to allow secretsmanager:GetSecretValue
data "aws_iam_policy_document" "secrets_access" {
  statement {
    effect = "Allow"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [var.rds_secret_arn]
  }
}

resource "aws_iam_policy" "secrets_policy" {
  name   = "${var.name}-secrets-policy"
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_role_policy_attachment" "secrets_attach" {
  role       = aws_iam_role.task_exec.name
  policy_arn = aws_iam_policy.secrets_policy.arn
}

# ECS Log group
resource "aws_cloudwatch_log_group" "ecs" {
  name = "/ecs/${var.name}"
  retention_in_days = 14
}

# Task definition: WordPress (uses Docker Hub image)
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.name}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "512"
  memory = "1024"
  execution_role_arn = aws_iam_role.task_exec.arn
  container_definitions = jsonencode([
    {
      name = "wordpress"
      image = "wordpress:php8.1-apache"
      essential = true
      portMappings = [{ containerPort = 80, hostPort = 80, protocol = "tcp" }]
      environment = [
         { name = "WORDPRESS_DB_NAME", value = var.wp_db_name }
      ]
      secrets = [
        { name = "WORDPRESS_DB_USER", valueFrom = var.rds_secret_arn } # we will parse in container startup
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.ecs.name
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "wordpress"
        }
      }
    }
  ])
}

# Task definition: Microservice (uses ECR repo)
resource "aws_ecs_task_definition" "micro" {
  family                   = "${var.name}-micro"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.task_exec.arn
  container_definitions = jsonencode([
    {
      name = "microservice"
      image = "${aws_ecr_repository.micro.repository_url}:latest"
      essential = true
      portMappings = [{ containerPort = 3000, hostPort = 3000, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.ecs.name
          awslogs-region = var.aws_region
          awslogs-stream-prefix = "microservice"
        }
      }
    }
  ])
}

# Security group for ECS tasks allowing outbound to RDS and inbound from ALB
resource "aws_security_group" "ecs_sg" {
  name = "${var.name}-ecs-sg"
  vpc_id = var.vpc_id
  description = "Allow traffic from ALB and to RDS"
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = []
    security_groups = [var.alb_security_group_id] # allow from ALB SG
  }
  egress {
    from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS service: WordPress
resource "aws_ecs_service" "wordpress" {
  name = "${var.name}-wordpress"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.wordpress_tg_arn
    container_name   = "wordpress"
    container_port   = 80
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200
}

# ECS service: Microservice
resource "aws_ecs_service" "micro" {
  name = "${var.name}-micro"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.micro.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.micro_tg_arn
    container_name   = "microservice"
    container_port   = 3000
  }
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent = 200
}
