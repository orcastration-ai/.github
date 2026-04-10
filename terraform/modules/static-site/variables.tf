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
