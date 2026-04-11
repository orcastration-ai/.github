variable "service_name" {
  description = "Service identifier (e.g. notification-service, x402-gateway-service)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be \"dev\" or \"prod\"."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "12-digit AWS account ID this stack targets."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "routes" {
  description = "API Gateway routes to create (e.g. [{method = \"POST\", path = \"/contact\"}])"
  type = list(object({
    method = string
    path   = string
  }))
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "additional_iam_statements" {
  description = "Additional IAM policy statements for the Lambda execution role (JSON-encoded list of statement objects)"
  type = list(object({
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC-attached Lambda (leave empty for no VPC)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for VPC-attached Lambda (leave empty for no VPC)"
  type        = list(string)
  default     = []
}
