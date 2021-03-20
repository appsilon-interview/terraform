# -----------------------------------------------------------------------------
# Service role allowing AWS to manage resources required for ECS
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

# -----------------------------------------------------------------------------
# Create the certificate
# -----------------------------------------------------------------------------

resource "aws_acm_certificate" "appsilon" {
  domain_name       = "${var.appsilon_subdomain}.${var.domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Validate the certificate
# -----------------------------------------------------------------------------

data "aws_route53_zone" "appsilon" {
  name = "${var.domain}."
}

resource "aws_route53_record" "appsilon_validation" {
  depends_on = [aws_acm_certificate.appsilon]
  for_each = {
    for dvo in aws_acm_certificate.appsilon.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 300
  type            = each.value.type
  zone_id         = data.aws_route53_zone.appsilon.zone_id
}

resource "aws_acm_certificate_validation" "appsilon" {
  certificate_arn         = aws_acm_certificate.appsilon.arn
  validation_record_fqdns = [for record in aws_route53_record.appsilon_validation : record.fqdn]
}

# -----------------------------------------------------------------------------
# Create VPC
# -----------------------------------------------------------------------------

resource "aws_vpc" "appsilon" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = true
}

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

# Create var.az_count private subnets for RDS, each in a different AZ
resource "aws_subnet" "appsilon_private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.appsilon.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.appsilon.id
}

# Create var.az_count public subnets for appsilon, each in a different AZ
resource "aws_subnet" "appsilon_public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.appsilon.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.appsilon.id
  map_public_ip_on_launch = true
}

# IGW for the public subnet
resource "aws_internet_gateway" "appsilon" {
  vpc_id = aws_vpc.appsilon.id
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id = aws_vpc.appsilon.main_route_table_id
  #tfsec:ignore:AWS006
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.appsilon.id
}

# -----------------------------------------------------------------------------
# Create security groups
# -----------------------------------------------------------------------------

# Internet to ALB
resource "aws_security_group" "appsilon_alb" {
  name        = "appsilon-alb"
  description = "Allow access on port 443 only to ALB"
  vpc_id      = aws_vpc.appsilon.id

  ingress {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
    #tfsec:ignore:AWS008
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB TO ECS
resource "aws_security_group" "appsilon_ecs" {
  name        = "appsilon-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.appsilon.id

  ingress {
    protocol        = "tcp"
    from_port       = "8080"
    to_port         = "8080"
    security_groups = [aws_security_group.appsilon_alb.id]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS to RDS
resource "aws_security_group" "appsilon_rds" {
  name        = "appsilon-rds"
  description = "allow inbound access from the appsilon tasks only"
  vpc_id      = aws_vpc.appsilon.id

  ingress {
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = [aws_security_group.appsilon_ecs.id]
  }

  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    #tfsec:ignore:AWS009
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Create RDS
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "appsilon" {
  name       = "appsilon"
  subnet_ids = aws_subnet.appsilon_private.*.id
}

resource "aws_db_instance" "appsilon" {
  name              = var.rds_db_name
  identifier        = "appsilon"
  username          = var.rds_username
  password          = var.rds_password
  port              = "5432"
  engine            = "postgres"
  engine_version    = "10.5"
  instance_class    = var.rds_instance
  allocated_storage = "10"
  #tfsec:ignore:AWS052
  storage_encrypted      = var.rds_storage_encrypted
  vpc_security_group_ids = [aws_security_group.appsilon_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.appsilon.name
  parameter_group_name   = "default.postgres10"
  multi_az               = false
  storage_type           = "gp2"
  publicly_accessible    = false

  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  apply_immediately           = false
  maintenance_window          = "sun:02:00-sun:04:00"
  skip_final_snapshot         = true
  copy_tags_to_snapshot       = true
  backup_retention_period     = 7
  backup_window               = "04:00-06:00"

  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------------------------------
# Create ECS cluster
# -----------------------------------------------------------------------------

resource "aws_ecs_cluster" "appsilon" {
  name = var.ecs_cluster_name
}

# -----------------------------------------------------------------------------
# Create logging
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "appsilon" {
  name = "/ecs/appsilon"
}

# -----------------------------------------------------------------------------
# Create IAM for logging
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "appsilon_log_publishing" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws:logs:${var.region}:*:log-group:/ecs/appsilon:*"]
  }
}

resource "aws_iam_policy" "appsilon_log_publishing" {
  name        = "appsilon-log-pub"
  path        = "/"
  description = "Allow publishing to cloudwach"

  policy = data.aws_iam_policy_document.appsilon_log_publishing.json
}

data "aws_iam_policy_document" "appsilon_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "appsilon_role" {
  name               = "appsilon-role"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.appsilon_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "appsilon_role_log_publishing" {
  role       = aws_iam_role.appsilon_role.name
  policy_arn = aws_iam_policy.appsilon_log_publishing.arn
}

# -----------------------------------------------------------------------------
# Create a task definition
# -----------------------------------------------------------------------------

locals {
  ecs_environment = [
    {
      name  = "DATABASE_URL",
      value = "postgres://${var.rds_username}:${var.rds_password}@${aws_db_instance.appsilon.endpoint}/${var.rds_db_name}"
    }
  ]

  ecs_container_definitions = [
    {
      image       = "shmileee/rshiny-example:${var.appsilon_version_tag}"
      name        = "appsilon",
      networkMode = "awsvpc",

      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ]

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.appsilon.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "ecs"
        }
      }

      environment = flatten([local.ecs_environment, var.environment])
    }
  ]
}

resource "aws_ecs_task_definition" "appsilon" {
  family                   = "appsilon"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.appsilon_role.arn

  container_definitions = jsonencode(local.ecs_container_definitions)
}

# -----------------------------------------------------------------------------
# Create the ECS service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "appsilon" {
  depends_on = [
    aws_ecs_task_definition.appsilon,
    aws_cloudwatch_log_group.appsilon,
    aws_alb_listener.appsilon
  ]
  name            = "appsilon-service"
  cluster         = aws_ecs_cluster.appsilon.id
  task_definition = aws_ecs_task_definition.appsilon.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.appsilon_ecs.id]
    subnets          = aws_subnet.appsilon_public.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.appsilon.id
    container_name   = "appsilon"
    container_port   = "8080"
  }
}

# -----------------------------------------------------------------------------
# Create the ALB log bucket
# -----------------------------------------------------------------------------

#tfsec:ignore:AWS002 tfsec:ignore:AWS017
resource "aws_s3_bucket" "appsilon" {
  bucket        = "appsilon-${var.region}-${var.appsilon_subdomain}-${var.domain}"
  acl           = "private"
  force_destroy = "true"
}

# -----------------------------------------------------------------------------
# Add IAM policy to allow the ALB to log to it
# -----------------------------------------------------------------------------

data "aws_elb_service_account" "main" {
}

data "aws_iam_policy_document" "appsilon" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.appsilon.arn}/alb/*"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "appsilon" {
  bucket = aws_s3_bucket.appsilon.id
  policy = data.aws_iam_policy_document.appsilon.json
}



# -----------------------------------------------------------------------------
# Create the ALB
# -----------------------------------------------------------------------------

#tfsec:ignore:AWS005
resource "aws_alb" "appsilon" {
  name            = "appsilon-alb"
  subnets         = aws_subnet.appsilon_public.*.id
  security_groups = [aws_security_group.appsilon_alb.id]

  access_logs {
    bucket  = aws_s3_bucket.appsilon.id
    prefix  = "alb"
    enabled = true
  }
}

# -----------------------------------------------------------------------------
# Create the ALB target group for ECS
# -----------------------------------------------------------------------------

resource "aws_alb_target_group" "appsilon" {
  name        = "appsilon-alb"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.appsilon.id
  target_type = "ip"
}

# -----------------------------------------------------------------------------
# Create the ALB listener
# -----------------------------------------------------------------------------

resource "aws_alb_listener" "appsilon" {
  load_balancer_arn = aws_alb.appsilon.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.appsilon.arn

  default_action {
    target_group_arn = aws_alb_target_group.appsilon.id
    type             = "forward"
  }
}

# -----------------------------------------------------------------------------
# Create Route 53 record to point to the ALB
# -----------------------------------------------------------------------------

resource "aws_route53_record" "appsilon" {
  zone_id = data.aws_route53_zone.appsilon.zone_id
  name    = "${var.appsilon_subdomain}.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_alb.appsilon.dns_name
    zone_id                = aws_alb.appsilon.zone_id
    evaluate_target_health = true
  }
}
