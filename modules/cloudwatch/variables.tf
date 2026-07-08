variable "name_prefix" {
  type = string
}

variable "alert_email" {
  description = "Email address to subscribe to the alerts SNS topic. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "db_instance_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
