##############################
# WORDPRESS TASK DEFINITION #
##############################

resource "aws_ecs_task_definition" "wordpress" {
  family                   = "${var.name}-wordpress"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.task_exec.arn
  task_role_arn      = aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name  = "wordpress"
      image = "wordpress:php8.1-apache"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "WORDPRESS_DB_NAME", value = var.wp_db_name }
      ]

      secrets = [
        {
          name      = "WORDPRESS_DB_USER"
          valueFrom = "${var.rds_secret_arn}:username::"
        },
        {
          name      = "WORDPRESS_DB_PASSWORD"
          valueFrom = "${var.rds_secret_arn}:password::"
        },
        {
          name      = "WORDPRESS_DB_HOST"
          valueFrom = "${var.rds_secret_arn}:host::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "wordpress"
        }
      }
    }
  ])
}


#####################################
# MICROSERVICE TASK DEFINITION     #
#####################################

resource "aws_ecs_task_definition" "microservice" {
  family                   = "${var.name}-micro"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.task_exec.arn
  task_role_arn      = aws_iam_role.task_exec.arn

  container_definitions = jsonencode([
    {
      name  = "microservice"
      image = "${var.microservice_image}"   # pass ECR image URL via module variable
      essential = true
      
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "microservice"
        }
      }
    }
  ])
}
