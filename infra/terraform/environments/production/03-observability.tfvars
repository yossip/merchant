# environments/production/03-observability.tfvars
aws_region  = "us-east-1"
environment = "production"

datadog_enabled   = true
coralogix_enabled = true

# Faster log delivery for production monitoring
firehose_buffering_size     = 1
firehose_buffering_interval = 60
