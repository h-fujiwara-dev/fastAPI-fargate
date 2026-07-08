variable "name_prefix" {
  type = string
}

variable "tagged_image_count_to_keep" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
