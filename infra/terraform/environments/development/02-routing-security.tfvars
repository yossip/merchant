# environments/development/02-routing-security.tfvars
aws_region  = "us-east-1"
environment = "development"

# Skip WAF in development to save costs and speed up delivery
enable_waf                   = false
waf_sampled_requests_enabled = false
