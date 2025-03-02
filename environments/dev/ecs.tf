#Create VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "ecs-vpc"
    Environment = "dev"
  }
}

# Create Public Subnets
resource "aws_subnet" "ecs_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "ecs-subnet1"
    Environment = "dev"
  }
}

resource "aws_subnet" "ecs_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "ecs-subnet2"
    Environment = "dev"
  }
}


###################
resource "aws_internet_gateway" "ecs_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ecs_igw"
  }
}

resource "aws_route_table" "ecs_routetable" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ecs_routetable"
  }
}


#Below is the one neededsec group
#resource "aws_security_group" "ecs_secgrp" {
#  name   = "ecs_secgrp"
#   description = "Allow TLS inbound traffic and all outbound traffic"
#  vpc_id = aws_vpc.main.id

#  ingress {
#    from_port   = 80
#    to_port     = 80
#    protocol    = "tcp"
#    cidr_blocks  = ["10.0.0.0/16"]
#  }
#}



# Existing Security Group
resource "aws_security_group" "ecs_secgrp" {
  name   = "ecs_secgrp"
   description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# New Outbound Rule: Ports 1024-65535
resource "aws_security_group_rule" "allow_outbound_high_ports" {
  type              = "egress"
  from_port         = 1024
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_secgrp.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# New Inbound Rule: HTTPS Traffic on Port 443
resource "aws_security_group_rule" "allow_inbound_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_secgrp.id
  cidr_blocks       = ["0.0.0.0/0"]
}




# Create ALB
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_secgrp.id]
  subnets            = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Load Balancer Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  name = "my-ecs_task_execution_role_policy_attachment"

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  roles      = [aws_iam_role.ecs_task_execution_role.name]
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}
##################
# ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities  = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name      = "my-app"
    image     = "${data.aws_ecr_repository.app_repo.repository_url}:latest"  # ECR image URL
941377135323.dkr.ecr.us-east-2.amazonaws.com/nikhil2025/deo-app:8c7eb9d634de60d524923138aaa39bfcea4098e2
    essential = true
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      },
    ]
  }])
}


#################
# ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.app_task.id
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
    security_groups  = [aws_security_group.ecs_secgrp.id]
    assign_public_ip = true
  }
}

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



