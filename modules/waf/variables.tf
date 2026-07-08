variable "name_prefix" {
  type = string
}

variable "rate_limit" {
  description = "Max requests per 5-minute window per IP before blocking."
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
