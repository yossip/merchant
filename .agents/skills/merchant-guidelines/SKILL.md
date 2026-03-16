---
name: b2c_merchant_guidelines
description: Core architectural rules and configurations for developing within the merchant repository.
---

# B2C Merchant Repository Guidelines

When operating within this repository, adhere strictly to the following architectural and deployment configurations:

## 1. Infrastructure (Terraform)
*   **Multi-Stage Pipeline**: Terraform is split into three core isolated state stages to minimize blast radius: `01-core-eks`, `02-routing-security`, and `03-observability`.
*   **Environments**: Do NOT hardcode variables. All environments (`development`, `integration`, `staging`, `production`) utilize `.tfvars` files located in `infra/terraform/environments/`.
*   **Safety Checks**: Before running `terraform apply`, you MUST run `terraform plan` and analyze whether the plan intends to `delete` any resources. Deletions in `staging` or `production` require manual human approval.
*   **High Availability**: Ensure resources (specifically VPC subnets and EKS node groups) are explicitly distributed across 3 Availability Zones.
*   **Secrets Management**: API Keys (like Datadog or Coralogix) must be read natively using the `aws_secretsmanager_secret_version` data source in `main.tf`, never stored as plain text or variables.

## 2. Kubernetes Deployments (Helm)
*   **Tooling**: Application deployments are managed exclusively via Helm (`merchant-core-api-chart`), not Kustomize or plain `kubectl apply`.
*   **High Availability (Anti-Affinity)**: The deployment templates default to 3 replicas and strictly enforce `podAntiAffinity` (weights 100 and 50) to algorithmically distribute pods across different physical EC2 nodes (`kubernetes.io/hostname`) and Availability Zones (`topology.kubernetes.io/zone`).
*   **Environment Overrides**: Environment-specific configurations are stored in `merchant-core-api-chart/environments/<env>.yaml`.
*   **Autoscaling Defaults**:
    *   **Development/Integration/Staging**: Use standard CPU Utilization scaling (defined in `values.yaml`).
    *   **Production**: Ensure the production override (`environments/production.yaml`) explicitly enables the advanced `HorizontalPodAutoscaler` tied to the Datadog API Latency external metric (`datadogMetric`).

## 3. Strict CI/CD Enforcement
*   **Console Access**: There is zero standing human access to `staging` or `production` environments. Human users cannot execute `kubectl` or `terraform` against production.
*   **Pipeline Source of Truth**: All mutations MUST originate automatically from within the GitHub Actions `.github/workflows/` pipeline using the designated CI/CD IAM role. Do not instruct users to manually execute `terraform apply` on staging/production.
