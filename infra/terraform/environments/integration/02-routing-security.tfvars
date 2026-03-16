# environments/integration/02-routing-security.tfvars
aws_region  = "us-east-1"
environment = "integration"

enable_waf                   = true
waf_sampled_requests_enabled = false
