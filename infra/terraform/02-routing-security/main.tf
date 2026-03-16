terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.11" }
  }
  # backend "s3" { key = "02-routing-security/terraform.tfstate" ... } 
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project      = "B2C-Merchant"
      Environment  = var.environment
      ManagedBy    = "Terraform"
      StateStage   = "02-routing-security"
      
      # AWS EDP / Cost Allocation Tags
      CostCenter   = "CC-12345"
      BusinessUnit = "E-Commerce"
      Owner        = "Platform-Security"
      Application  = "Merchant-Edge"
    }
  }
}

variable "aws_region" { default = "us-east-1" }
variable "environment" { default = "prod" }

# In a real setup, we use terraform_remote_state to get the EKS cluster data
# data "terraform_remote_state" "eks" { ... }

# provider "helm" {
#   kubernetes {
#     host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
#     cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_ca)
#     ...
#   }
# }

# -------------------------------------------------------------------------
# Edge Delivery & Security (CloudFront, WAF, Lambda@Edge)
# -------------------------------------------------------------------------

resource "aws_wafv2_web_acl" "edge_protection" {
  count       = var.enable_waf ? 1 : 0
  name        = "merchant-edge-protection-${var.environment}"
  scope       = "CLOUDFRONT"
  description = "Basic WAF rules for rate limiting and OWASP Top 10"

  default_action { allow {} }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "edge-protection-metrics"
    sampled_requests_enabled   = var.waf_sampled_requests_enabled
  }
}

resource "aws_cloudfront_distribution" "merchant_cdn" {
  origin {
    domain_name = "loadbalancer.example.com" # Should be ALB data source 
    origin_id   = "EKS-ALB-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  web_acl_id          = var.enable_waf ? aws_wafv2_web_acl.edge_protection[0].arn : null
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "EKS-ALB-Origin"
    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type   = "viewer-request"
      # lambda_arn   = aws_lambda_function.edge_auth.qualified_arn
      lambda_arn   = "arn:aws:lambda:us-east-1:1234567890:function:edge-auth:1"
      include_body = false
    }
  }

  restrictions { geo_restriction { restriction_type = "none" } }
  viewer_certificate { cloudfront_default_certificate = true }
}

# -------------------------------------------------------------------------
# Galaxy Ingress Controller Setup (Helm Release)
# -------------------------------------------------------------------------
resource "helm_release" "galaxy_ingress" {
  name       = "galaxy-ingress"
  repository = "https://charts.galaxy-ingress.io"
  chart      = "galaxy-ingress"
  namespace  = "kube-system"

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "nlb"
  }
  
  set { name = "controller.nodeSelector.role", value = "ingress" }
  set { name = "controller.tolerations[0].key", value = "role" }
  set { name = "controller.tolerations[0].operator", value = "Equal" }
  set { name = "controller.tolerations[0].value", value = "ingress" }
  set { name = "controller.tolerations[0].effect", value = "NoSchedule" }
}
