resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}


# grant permissions to the ECS service

# IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  name   = "${var.project_name}-ecs-task-execution-secrets-policy"
  role   = aws_iam_role.ecs_task_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "secretsmanager:GetSecretValue",
        Resource = [
          "arn:aws:secretsmanager:ap-northeast-1:565106043526:secret:konnichiwa/konnichiwa-api-key-*"
        ]
      }
    ]
  })
}

# Attach the policy required for ECS tasks to run
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Tasks (Application Role)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach a policy to the task role
# use aws_iam_role_policy instead of aws_iam_role_policy_attachment
# as this policy needs to be customized for the app, e.g. allow access
# to S3, DynamoDB, etc.
resource "aws_iam_role_policy" "ecs_task_role_policy" {
  name   = "${var.project_name}-ecs-task-role-policy"
  role   = aws_iam_role.ecs_task_role.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",  # Allow reading from S3
          "logs:CreateLogStream",
          "logs:PutLogEvents" # Allow writing to CloudWatch Logs
        ],
        Resource = "*"
      }
    ]
  })
}

# IAM Role for EC2 instances in ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.project_name}-ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach ECS instance policy to the instance role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# SSH access to the EC2 instances
resource "aws_iam_role_policy_attachment" "ecs_instance_connect" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceConnect"
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.project_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Security group for ECS EC2 instances
# Applied to EC2 instances that host containers
resource "aws_security_group" "ecs_instances" {
  name        = "${var.project_name}-ecs-instances"
  description = "Security group for ECS EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    # This restricts the source to only the ALB’s security group, ensuring
    # that only traffic routed through the ALB can reach the instances.
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.ssh_allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-instances"
  }
}

# Launch template for ECS EC2 instances
resource "aws_launch_template" "ecs_instance" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  # security_group_names = [ aws_security_group.ecs_instances.name ]
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
    EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ecs-instance"
    }
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs_cluster" {
  name                = "${var.project_name}-ecs-asg"
  vpc_zone_identifier = [for subnet in aws_subnet.public : subnet.id]
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "EC2"
  health_check_grace_period = 300  # Give ECS time to start tasks before health check kicks in
  min_size            = var.min_capacity
  max_size            = var.max_capacity
  desired_capacity    = var.desired_capacity

  launch_template {
    id      = aws_launch_template.ecs_instance.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = false
  }
}

# Data source to get the latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_ecs_task_definition" "main" {
  family       = "${var.project_name}-task"
  network_mode = "bridge"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-container"
      image     = "${aws_ecr_repository.main.repository_url}:latest"
      cpu       = var.container_cpu
      memory    = var.container_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = 0  # Dynamic port mapping
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.main.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb" "main" {
  name               = "main-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]

  enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}
resource "aws_lb_target_group" "main" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type  = "instance"

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-1:565106043526:certificate/d8a4dc80-129a-498f-9b0b-662aa78052c2"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.app_count
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "${var.project_name}-container"
    container_port   = var.container_port
  }

  placement_constraints {
    type = "distinctInstance"
  }

  # Ensure service waits for ALB and ASG to be ready
  depends_on = [
    aws_lb_listener.http,
    aws_autoscaling_group.ecs_cluster
  ]
}

output "ecs_launch_template_name" {
  value = aws_launch_template.ecs_instance.name
}

output "ecs_launch_template_id" {
  value = aws_launch_template.ecs_instance.id
}
