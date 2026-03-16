variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. development, integration, staging, production)"
  type        = string
}

variable "enable_waf" {
  description = "Whether to enable AWS WAF on CloudFront"
  type        = bool
  default     = true
}

variable "waf_sampled_requests_enabled" {
  description = "Whether AWS WAF should store sampled requests"
  type        = bool
  default     = true
}


