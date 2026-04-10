variable "domain_name" {
  description = "Fully qualified domain name for the static site (e.g. orcastration.ai)"
  type        = string
}

variable "zone_id" {
  description = "Route 53 hosted zone ID for DNS records"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "web_acl_id" {
  description = "WAFv2 WebACL ARN for CloudFront. Empty string = no WAF."
  type        = string
  default     = ""
}

variable "redirect_from" {
  description = "Optional domain to 301-redirect to domain_name (e.g. www.example.com → example.com). Leave empty to disable."
  type        = string
  default     = ""
}

variable "spa_mode" {
  description = "Serve /index.html with 200 for unknown routes (enables client-side SPA routing). When false, unknown routes return /404.html with 404."
  type        = bool
  default     = false
}
