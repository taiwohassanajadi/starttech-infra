terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-vpc"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name_prefix}-igw"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-subnet-1"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "public"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-public-subnet-2"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "public"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-1"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "private"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name        = "${local.name_prefix}-private-subnet-2"
    Project     = var.project_name
    Environment = var.environment
    Tier        = "private"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name_prefix}-public-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-nat-eip"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name        = "${local.name_prefix}-nat-gateway"
    Project     = var.project_name
    Environment = var.environment
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${local.name_prefix}-private-rt"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP from internet"
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

  tags = {
    Name        = "${local.name_prefix}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "backend" {
  name        = "${local.name_prefix}-backend-sg"
  description = "Security group for backend EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow backend traffic from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "Allow SSH within VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-backend-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow Redis from backend EC2"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-redis-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}
resource "aws_ecr_repository" "backend" {
  name                 = "${local.name_prefix}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${local.name_prefix}-backend-ecr"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/${var.project_name}/${var.environment}/backend"
  retention_in_days = 7

  tags = {
    Name        = "${local.name_prefix}-backend-logs"
    Project     = var.project_name
    Environment = var.environment
  }
}
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${local.name_prefix}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name        = "${local.name_prefix}-redis-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name        = "${local.name_prefix}-redis"
    Project     = var.project_name
    Environment = var.environment
  }
}
resource "aws_s3_bucket" "frontend" {
  bucket        = "${local.name_prefix}-frontend-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name        = "${local.name_prefix}-frontend"
    Project     = var.project_name
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${local.name_prefix}-frontend-oac"
  description                       = "OAC for frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "frontend-s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "frontend-s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${local.name_prefix}-frontend-cloudfront"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}
resource "aws_iam_role" "backend_ec2" {
  name = "${local.name_prefix}-backend-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-backend-ec2-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "backend_ecr_readonly" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "backend_ssm" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "backend_cloudwatch" {
  role       = aws_iam_role.backend_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "backend" {
  name = "${local.name_prefix}-backend-instance-profile"
  role = aws_iam_role.backend_ec2.name
}
resource "aws_launch_template" "backend" {
  name_prefix   = "${local.name_prefix}-backend-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [
    aws_security_group.backend.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.backend.name
  }
  user_data = base64encode(<<-EOF
#!/bin/bash
dnf update -y

dnf install -y docker

systemctl enable docker
systemctl start docker

aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.backend.repository_url}

docker pull ${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}

docker run -d --name backend -p 8080:8080 \
  -e PORT=8080 \
  -e MONGO_URI=${var.mongo_uri} \
  -e JWT_SECRET_KEY=${var.jwt_secret_key} \
  -e DB_NAME=starttechdb \
  -e ENABLE_CACHE=true \
  -e REDIS_ADDR="${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379" \
  -e LOG_LEVEL=INFO \
  ${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}
EOF
  )
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${local.name_prefix}-backend-instance"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${local.name_prefix}-backend-launch-template"
    Project     = var.project_name
    Environment = var.environment
  }
}
resource "aws_lb" "backend" {
  name               = "${local.name_prefix}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name        = "${local.name_prefix}-backend-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "backend" {
  name     = "${local.name_prefix}-backend-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${local.name_prefix}-backend-tg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_autoscaling_group" "backend" {
  name                = "${local.name_prefix}-backend-asg"
  desired_capacity    = 2
  min_size            = 2
  max_size            = 3
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  target_group_arns   = [aws_lb_target_group.backend.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-backend-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}