# Derived locals for consistent naming and tagging across all resources

locals {
  name_prefix = "juice-shop-${var.environment}"

  tags = merge(var.tags, {
    Environment = var.environment
    Owner       = var.owner_tag
    ManagedBy   = "terraform"
  })
}
