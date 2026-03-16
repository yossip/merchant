# environments/staging/03-observability.tfvars
aws_region  = "us-east-1"
environment = "staging"

datadog_enabled   = true
coralogix_enabled = true

firehose_buffering_size     = 1
firehose_buffering_interval = 60
