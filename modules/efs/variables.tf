variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_app_subnet_ids" {
  type = list(string)
}

variable "wordpress_ecs_sg_id" {
  description = "Security group ID of the WordPress ECS service allowed to mount this filesystem."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
