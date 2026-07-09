resource "aws_security_group" "efs" {
  name        = "${var.name_prefix}-efs-sg"
  description = "Allow NFS access from the WordPress ECS service only."
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from WordPress ECS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.wordpress_ecs_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-efs-sg" })
}

resource "aws_efs_file_system" "this" {
  encrypted = true

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-efs" })
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.private_app_subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# www-data (uid/gid 33:33) is the fixed, Debian-standard user in the official
# wordpress:*-apache image — matches the ownership the container writes as.
resource "aws_efs_access_point" "wp_content" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 33
    gid = 33
  }

  root_directory {
    path = "/wordpress/wp-content"

    creation_info {
      owner_uid   = 33
      owner_gid   = 33
      permissions = "0755"
    }
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-efs-wp-content" })
}
