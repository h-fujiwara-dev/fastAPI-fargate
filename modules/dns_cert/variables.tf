variable "domain_name" {
  type = string
}

variable "create_hosted_zone" {
  description = "true to create a new Route 53 hosted zone, false to look up an existing one by name."
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
