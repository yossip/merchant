variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. development, integration, staging, production)"
  type        = string
}

variable "datadog_enabled" {
  description = "Whether to deploy the Datadog agent"
  type        = bool
  default     = true
}

variable "coralogix_enabled" {
  description = "Whether to deploy the Coralogix/Firehose logging pipeline"
  type        = bool
  default     = true
}

variable "firehose_buffering_size" {
  description = "Firehose buffer size (MB)"
  type        = number
  default     = 1
}

variable "firehose_buffering_interval" {
  description = "Firehose buffer interval (Seconds)"
  type        = number
  default     = 60
}
