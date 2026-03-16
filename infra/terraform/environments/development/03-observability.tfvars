# environments/development/03-observability.tfvars
aws_region  = "us-east-1"
environment = "development"

datadog_enabled   = true
coralogix_enabled = true

# Max buffering to save on Kinesis Firehose API calls in dev
firehose_buffering_size     = 5
firehose_buffering_interval = 300
