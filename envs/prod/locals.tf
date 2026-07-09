locals {
  enable_https = var.domain_name != ""

  # Distinct name prefix for all WordPress resources, so they never collide
  # with the FastAPI app's resources sharing the same name_prefix.
  wp_name_prefix = "${var.name_prefix}-wp"

  common_tags = merge(var.tags, {
    Project     = var.name_prefix
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}
