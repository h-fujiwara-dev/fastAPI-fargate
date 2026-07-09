locals {
  db_host_with_port = "${var.db_host}:${var.db_port}"

  # eval()'d by wp-config-docker.php's WORDPRESS_CONFIG_EXTRA hook — pins the
  # site URL to this service's own ALB since no domain is configured yet.
  wp_config_extra = "define('WP_HOME','http://${var.wordpress_alb_dns_name}'); define('WP_SITEURL','http://${var.wordpress_alb_dns_name}');"
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ---- Security group: only the WordPress ALB may reach the app on container_port ----

resource "aws_security_group" "ecs_service" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "Allow inbound app traffic from the WordPress ALB only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "App traffic from WordPress ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-ecs-sg" })
}

# ---- IAM roles ----

data "aws_iam_policy_document" "ecs_tasks_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name_prefix}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution_managed" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  name = "${var.name_prefix}-ecs-task-execution-secrets"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [var.db_secret_arn, var.api_key_secret_arn, var.wp_salts_secret_arn]
    }]
  })
}

resource "aws_iam_role" "task_role" {
  name               = "${var.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume.json

  tags = var.tags
}

# EFS access-point IAM authorization belongs on the task role (the identity
# the running container mounts as), not the execution role.
resource "aws_iam_role_policy" "task_efs_access" {
  name = "${var.name_prefix}-ecs-task-efs-access"
  role = aws_iam_role.task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["elasticfilesystem:ClientMount", "elasticfilesystem:ClientWrite"]
      Resource = var.efs_file_system_arn
      Condition = {
        StringEquals = {
          "elasticfilesystem:AccessPointArn" = var.efs_access_point_arn
        }
      }
    }]
  })
}

# ---- Task definition & service ----

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.name_prefix}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_role.arn

  volume {
    name = "wp-content"

    efs_volume_configuration {
      file_system_id     = var.efs_file_system_id
      transit_encryption = "ENABLED"

      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "WORDPRESS_DB_HOST", value = local.db_host_with_port },
        { name = "WORDPRESS_DB_NAME", value = var.db_name },
        { name = "FASTAPI_API_BASE_URL", value = "http://${var.fastapi_alb_dns_name}" },
        { name = "WORDPRESS_CONFIG_EXTRA", value = local.wp_config_extra },
      ]

      secrets = [
        { name = "WORDPRESS_DB_USER", valueFrom = "${var.db_secret_arn}:username::" },
        { name = "WORDPRESS_DB_PASSWORD", valueFrom = "${var.db_secret_arn}:password::" },
        { name = "FASTAPI_API_KEY", valueFrom = var.api_key_secret_arn },
        { name = "WORDPRESS_AUTH_KEY", valueFrom = "${var.wp_salts_secret_arn}:AUTH_KEY::" },
        { name = "WORDPRESS_SECURE_AUTH_KEY", valueFrom = "${var.wp_salts_secret_arn}:SECURE_AUTH_KEY::" },
        { name = "WORDPRESS_LOGGED_IN_KEY", valueFrom = "${var.wp_salts_secret_arn}:LOGGED_IN_KEY::" },
        { name = "WORDPRESS_NONCE_KEY", valueFrom = "${var.wp_salts_secret_arn}:NONCE_KEY::" },
        { name = "WORDPRESS_AUTH_SALT", valueFrom = "${var.wp_salts_secret_arn}:AUTH_SALT::" },
        { name = "WORDPRESS_SECURE_AUTH_SALT", valueFrom = "${var.wp_salts_secret_arn}:SECURE_AUTH_SALT::" },
        { name = "WORDPRESS_LOGGED_IN_SALT", valueFrom = "${var.wp_salts_secret_arn}:LOGGED_IN_SALT::" },
        { name = "WORDPRESS_NONCE_SALT", valueFrom = "${var.wp_salts_secret_arn}:NONCE_SALT::" },
      ]

      mountPoints = [
        {
          sourceVolume  = "wp-content"
          containerPath = "/var/www/html/wp-content"
          readOnly      = false
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}

resource "aws_ecs_service" "app" {
  name            = "${var.name_prefix}-service"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  # EFS volumes on Fargate require platform version >= 1.4.0.
  platform_version = "1.4.0"

  network_configuration {
    subnets          = var.private_app_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # WordPress + EFS mount negotiation is slower to first-healthy than the lean FastAPI container.
  health_check_grace_period_seconds = 90
}

# ---- Auto scaling ----

resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.name_prefix}-ecs-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 60
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
