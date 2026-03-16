# environments/staging/02-routing-security.tfvars
aws_region  = "us-east-1"
environment = "staging"

# Staging mirrors production
enable_waf                   = true
waf_sampled_requests_enabled = true
