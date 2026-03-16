# environments/production/02-routing-security.tfvars
aws_region  = "us-east-1"
environment = "production"

# Full security suite for production
enable_waf                   = true
waf_sampled_requests_enabled = true
