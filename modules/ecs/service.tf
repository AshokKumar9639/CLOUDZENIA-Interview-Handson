###########################
# ECS SECURITY GROUP      #
###########################

resource "aws_security_group" "ecs_sg" {
  name        = "${var.name}-ecs-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow ALB → ECS traffic"
    from_port       = 0
    to_port         = 65535
    protocol        = "-1"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###########################
# WORDPRESS SERVICE       #
###########################

resource "aws_ecs_service" "wordpress" {
  name            = "${var.name}-wordpress"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.wordpress_tg_arn
    container_name   = "wordpress"
    container_port   = 80
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [desired_count]
  }
}


###########################
# MICROSERVICE SERVICE    #
###########################

resource "aws_ecs_service" "microservice" {
  name            = "${var.name}-micro"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.microservice.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.micro_tg_arn
    container_name   = "microservice"
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  lifecycle {
    ignore_changes = [desired_count]
  }
}
