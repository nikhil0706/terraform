
resource "aws_security_group" "ecs_secgrp" {
  name   = "ecs_secgrp"
   description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
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
  from_port         = 80
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_secgrp.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# New Inbound Rule: HTTPS Traffic on Port 443
resource "aws_security_group_rule" "allow_inbound_https" {
  type              = "ingress"
  from_port         = 80
  to_port           = 65535 #change later
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_secgrp.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]  # Replace with your subnets
  security_group_ids = [aws_security_group.ecs_secgrp.id]  # Optional: Security group for the endpoint

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]  # Replace with your subnets
  security_group_ids = [aws_security_group.ecs_secgrp.id]  # Optional: Security group for the endpoint

  private_dns_enabled = true
}



# Create ALB & ALB Security group 

resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  # Allow inbound HTTP traffic on port 80 from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic on port 443 from anywhere (if needed)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.ecs_pubsubnet1.id, aws_subnet.ecs_pubsubnet2.id]
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 4000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health" # Ensure this path exists in your app
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"     # Must return HTTP 200
  }
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
#941377135323.dkr.ecr.us-east-2.amazonaws.com/nikhil2025/deo-app:8c7eb9d634de60d524923138aaa39bfcea4098e2
    essential = true
    portMappings = [
      {
        containerPort = 4000
        hostPort      = 4000
        protocol      = "tcp"
      },
    ]
   #healthCheck = {
   #   command     = ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
   #   interval    = 30
   #   timeout     = 5
   #   retries     = 3
   #   startPeriod = 60
   # }
  logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_log_group.name
        awslogs-region        = "us-east-2"  # Replace with your region
        awslogs-stream-prefix = "ecs"
      }
    }
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

  #force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.ecs_subnet_1.id, aws_subnet.ecs_subnet_2.id]
    security_groups  = [aws_security_group.ecs_secgrp.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "my-app"
    container_port   = 4000
  }
  depends_on = [aws_lb_listener.front_end]
}

