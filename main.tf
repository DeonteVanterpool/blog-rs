provider "aws" {
  region = var.region
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

resource "aws_cloudwatch_log_group" "log_group" {
  name = "/ecs/deontevanterpool-logs"
}

resource "aws_ecs_task_definition" "application_task" {
  family                   = "deontevanterpool_task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  memory                   = 256
  cpu                      = 256
  execution_role_arn       = aws_iam_role.deontevanterpool_ecsTaskExecutionRole.arn
  container_definitions    = jsonencode([
    {
      name      = "application"
      image     = aws_ecr_repository.deontevanterpool_ecr_repo.repository_url
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-create-group" = "true"
          "awslogs-group"        = aws_cloudwatch_log_group.log_group.name
          "awslogs-region"       = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
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

  depends_on = [aws_instance.deontevanterpool]

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
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Elastic IP for the EC2 instance
resource "aws_eip" "deontevanterpool_eip" {
  domain = "vpc"
}

# EC2 instance (single) with EIP
resource "aws_instance" "deontevanterpool" {
  ami                         = data.aws_ami.ecs_optimized.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ecs_instance_profile.name
  subnet_id                   = aws_default_subnet.default_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true   # Give it a public IP initially; EIP will override.
  key_name = "deonte@terraform"

  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.deontevanterpool_ecs_cluster.name} >> /etc/ecs/ecs.config
    systemctl restart ecs
  EOF

  tags = {
    Name = "deontevanterpool"
  }
}

# Associate the EIP with the instance
resource "aws_eip_association" "deontevanterpool_eip_association" {
  instance_id   = aws_instance.deontevanterpool.id
  allocation_id = aws_eip.deontevanterpool_eip.id
}

# Output the static IP
output "static_ip" {
  description = "Static public IP of the EC2 instance"
  value       = aws_eip.deontevanterpool_eip.public_ip
}

resource "aws_s3_bucket" "portfolio_entries" {
  bucket = var.portfolio_entries_bucket

  tags = {
    Name        = "deontevanterpool"
  }
}

resource "aws_s3_bucket" "templates" {
  bucket = var.templates_bucket

  tags = {
    Name        = "deontevanterpool"
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = var.assets_bucket

  tags = {
    Name        = "deontevanterpool"
  }
}

resource "aws_s3_bucket" "env" {
  bucket = var.env_bucket

  tags = {
    Name        = "deontevanterpool"
  }
}

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.assets.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "access_identity" {
  comment = "deontevanterpool access_identity"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

locals {
  s3_origin_id = aws_s3_bucket.assets.bucket_regional_domain_name
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.assets.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.access_identity.cloudfront_access_identity_path
    }
  }
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "deontevanterpool_s3_distribution"

  # AWS Managed Caching Policy (CachingDisabled)
  default_cache_behavior {
    # Using the CachingDisabled managed policy ID:
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "deontevanterpool-assets-cloudfront-distribution"
  }
}
