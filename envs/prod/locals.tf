locals {
  enable_https = var.domain_name != ""

  common_tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
