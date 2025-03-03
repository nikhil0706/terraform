output "load_balancer_url" {
  description = "The URL of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name
}

output "vpc_id" {
  description = "The ID of the created VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the created subnets"
  value       = [aws_subnet.ecs_subnet_1.id , aws_subnet.ecs_subnet_1.id]
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ecs_secgrp.id
}

output "ecs_cluster_id" {
  description = "The ID of the ECS Cluster"
  value       = aws_ecs_cluster.ecs_cluster.id
}

output "task_definition_arn" {
  description = "The ARN of the ECS Task Definition"
  value       = aws_ecs_task_definition.app_task.arn
}

output "ecr_image_url" {
  description = "ECR repository URL for the image"
  value       = "${data.aws_ecr_repository.app_repo.repository_url}:latest"
}

output "alb_url" {
  description = "Application load balancer "
  value       = aws_lb.app_lb.dns_name
}
