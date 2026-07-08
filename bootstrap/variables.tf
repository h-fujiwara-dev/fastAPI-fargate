variable "aws_region" {
  description = "AWS region to create the state bucket/lock table in."
  type        = string
  default     = "ap-northeast-1"
}

variable "name_prefix" {
  description = "Prefix used for naming bootstrap resources."
  type        = string
  default     = "fastapi-fargate"
}
