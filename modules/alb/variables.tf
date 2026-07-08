variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "container_port" {
  type    = number
  default = 80
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "enable_https" {
  description = "Set to true once a domain + ACM certificate are available."
  type        = bool
  default     = false
}

variable "certificate_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
