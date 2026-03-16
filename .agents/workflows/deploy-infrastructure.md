---
description: How to safely deploy infrastructure in the merchant repository using Terraform
---

# Deploy Terraform Infrastructure Workflow

When requested to deploy or update infrastructure for a specific environment (`$ENV`), follow these instructions precisely.

1.  Navigate to the specific Terraform stage directory (e.g., `01-core-eks`, `02-routing-security`, or `03-observability`).
    ```bash
    cd infra/terraform/01-core-eks
    ```
2.  Initialize the working directory.
    ```bash
    terraform init
    ```
3.  Execute a `terraform plan` referencing the accurate environment variables file. Extract the plan to an output file.
    ```bash
    terraform plan -var-file=../../environments/$ENV/01-core-eks.tfvars -out=tfplan
    ```
4.  Export the plan into a JSON format so it can be mechanically analyzed.
    ```bash
    terraform show -json tfplan > tfplan.json
    ```
5.  Analyze `tfplan.json` for any destructive actions. If the `change.actions` array contains `["delete"]`:
    *   STOP the workflow.
    *   Notify the human operator that destructive changes are required, and wait for explicit manual approval.
6.  If no destructive actions exist (or manual approval was given), apply the saved plan.
    ```bash
    terraform apply "tfplan"
    ```
7.  Repeat for any subsequent dependent stages.
