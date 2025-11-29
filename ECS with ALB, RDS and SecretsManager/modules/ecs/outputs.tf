output "cluster_id" { value = aws_ecs_cluster.this.id }

output "ecr_repo" { value = aws_ecr_repository.micro.repository_url }
