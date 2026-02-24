provider "aws" {
  region = "us-east-1"
}

# IAM role for EC2 instances in the ECS cluster
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attach" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# IAM role for ECS task execution (pulling images, etc.)
resource "aws_iam_role" "deontevanterpool_ecsTaskExecutionRole" {
  name               = "deontevanterpool_ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "deontevanterpool_ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.deontevanterpool_ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# ECR repository
resource "aws_ecr_repository" "deontevanterpool_ecr_repo" {
  name = "deontevanterpool-ecr-repo"
}

# ECS cluster
resource "aws_ecs_cluster" "deontevanterpool_ecs_cluster" {
  name = "deontevanterpool-ecs-cluster"
}

# ECS task definition (bridge mode)
resource "aws_ecs_task_definition" "application_task" {
  family                   = "deontevanterpool_task"
  network_mode             = "bridge"          # changed from awsvpc
  requires_compatibilities = ["EC2"]           # still valid
  memory                   = 256
  cpu                      = 256
  execution_role_arn       = aws_iam_role.deontevanterpool_ecsTaskExecutionRole.arn
  container_definitions    = jsonencode([
    {
      name      = "application"
      image     = aws_ecr_repository.deontevanterpool_ecr_repo.repository_url
      essential = true
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000      # explicitly map to the same port on the host
          protocol      = "tcp"
        }
      ]
      memory    = 256
      cpu       = 256
    }
  ])
}

# ECS service (no network_configuration)
resource "aws_ecs_service" "deontevanterpool_service" {
  name            = "deontevanterpool-app-service"
  cluster         = aws_ecs_cluster.deontevanterpool_ecs_cluster.id
  task_definition = aws_ecs_task_definition.application_task.arn
  launch_type     = "EC2"
  desired_count   = 1

  depends_on = [aws_instance.asims_notebook]

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Default VPC and subnets
resource "aws_default_vpc" "default_vpc" {}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "us-east-1a"
}

# Security group for the EC2 instance (and for tasks if needed)
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2-security-group"
  description = "Allow traffic to the instance and tasks"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
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

# Security group for ECS tasks (attached to task ENIs)
resource "aws_security_group" "service_security_group" {
  name        = "ecs-service-sg"
  description = "Allow traffic to tasks on port 4000"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # Direct access to tasks via instance's public IP? No, tasks have separate ENIs.
    # But with awsvpc, tasks have their own ENI and can have public IPs if assign_public_ip=true.
    # However, EC2 launch type does not support assign_public_ip=true. So tasks will have private IPs only.
    # To access them directly, you'd need to go through the host instance's IP and do port mapping (bridge mode) or use a load balancer.
    # Since you want a static IP, we'll access the application via the host's public IP if we use bridge mode.
    # But your task definition uses awsvpc. So we need to reconsider.
  }
}

# Elastic IP for the EC2 instance
resource "aws_eip" "deontevanterpool_eip" {
  domain = "vpc"
}

# EC2 instance (single) with EIP
resource "aws_instance" "asims_notebook" {
  ami                         = data.aws_ami.ecs_optimized.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  subnet_id                   = aws_default_subnet.default_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true   # Give it a public IP initially; EIP will override.

  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.deontevanterpool_ecs_cluster.name} >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name = "asims-notebook"
  }
}

# Associate the EIP with the instance
resource "aws_eip_association" "deontevanterpool_eip_association" {
  instance_id   = aws_instance.asims_notebook.id
  allocation_id = aws_eip.deontevanterpool_eip.id
}

# Output the static IP
output "static_ip" {
  description = "Static public IP of the EC2 instance"
  value       = aws_eip.deontevanterpool_eip.public_ip
}
