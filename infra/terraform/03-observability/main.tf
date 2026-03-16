terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    helm = { source = "hashicorp/helm", version = "~> 2.11" }
  }
  # backend "s3" { key = "03-observability/terraform.tfstate" ... } 
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project      = "B2C-Merchant"
      Environment  = var.environment
      ManagedBy    = "Terraform"
      StateStage   = "03-observability"

      # AWS EDP / Cost Allocation Tags
      CostCenter   = "CC-12345"
      BusinessUnit = "E-Commerce"
      Owner        = "Platform-SRE"
      Application  = "Merchant-Telemetry"
    }
  }
}

# -------------------------------------------------------------------------
# Secrets Management (AWS Secrets Manager)
# -------------------------------------------------------------------------

data "aws_secretsmanager_secret_version" "datadog_api_key" {
  count     = var.datadog_enabled ? 1 : 0
  secret_id = "merchant/${var.environment}/datadog-api-key"
}

data "aws_secretsmanager_secret_version" "coralogix_private_key" {
  count     = var.coralogix_enabled ? 1 : 0
  secret_id = "merchant/${var.environment}/coralogix-private-key"
}

# -------------------------------------------------------------------------
# Observability (Datadog APM & Coralogix Logging via Firehose)
# -------------------------------------------------------------------------

resource "helm_release" "datadog" {
  count            = var.datadog_enabled ? 1 : 0
  name             = "datadog"
  repository       = "https://helm.datadoghq.com"
  chart            = "datadog"
  namespace        = "monitoring"
  create_namespace = true

  set { name = "datadog.apiKey", value = data.aws_secretsmanager_secret_version.datadog_api_key[0].secret_string }
  set { name = "datadog.site", value = "datadoghq.com" }
  set { name = "datadog.apm.portEnabled", value = "true" }
  set_list { name = "datadog.tolerations", value = ["{\"operator\": \"Exists\"}"] }
}

# S3 Backup
resource "aws_s3_bucket" "coralogix_firehose_backup" {
  count  = var.coralogix_enabled ? 1 : 0
  bucket = "merchant-logs-backup-${var.environment}"
}

# Firehose Role
resource "aws_iam_role" "firehose_role" {
  count              = var.coralogix_enabled ? 1 : 0
  name               = "firehose_coralogix_${var.environment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" } }]
  })
}

# Firehose
resource "aws_kinesis_firehose_delivery_stream" "coralogix_stream" {
  count       = var.coralogix_enabled ? 1 : 0
  name        = "merchant-logs-to-coralogix-${var.environment}"
  destination = "http_endpoint"
  http_endpoint_configuration {
    url        = "https://ingress.coralogix.com/aws/firehose"
    name       = "Coralogix"
    access_key = data.aws_secretsmanager_secret_version.coralogix_private_key[0].secret_string
    role_arn   = aws_iam_role.firehose_role[0].arn
    
    buffering_size     = var.firehose_buffering_size
    buffering_interval = var.firehose_buffering_interval
    s3_backup_mode = "FailedDataOnly"
    s3_configuration {
      role_arn           = aws_iam_role.firehose_role[0].arn
      bucket_arn         = aws_s3_bucket.coralogix_firehose_backup[0].arn
    }
  }
}

# IRSA for Fluent-Bit
# ... Would use terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks as before ...

resource "helm_release" "coralogix_logger" {
  count            = var.coralogix_enabled ? 1 : 0
  name             = "coralogix-fluent-bit"
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit" 
  namespace        = "logging"
  create_namespace = true

  set { name = "serviceAccount.name", value = "coralogix-fluent-bit" }
  set {
    name  = "config.outputs"
    value = <<EOF
[OUTPUT]
    Name            kinesis_firehose
    Match           *
    region          ${var.aws_region}
    delivery_stream ${aws_kinesis_firehose_delivery_stream.coralogix_stream[0].name}
EOF
  }

  set_list { name = "tolerations", value = ["{\"operator\": \"Exists\"}"] }
}
