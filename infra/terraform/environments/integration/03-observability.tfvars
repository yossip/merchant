# environments/integration/03-observability.tfvars
aws_region  = "us-east-1"
environment = "integration"

datadog_enabled   = true
coralogix_enabled = true

firehose_buffering_size     = 5
firehose_buffering_interval = 60
