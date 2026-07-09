variable "name_prefix" {
  type = string
}

variable "repository_name" {
  description = "Overrides the derived \"<name_prefix>-app\" repository name when set."
  type        = string
  default     = null
}

variable "tagged_image_count_to_keep" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
