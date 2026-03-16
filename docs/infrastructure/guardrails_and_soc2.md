# Infrastructure Guardrails & SOC 2 Compliance

For a B2C Merchant Solution, trust is paramount. This document details the infrastructure guardrails we implement to enforce security automatically and how our architecture maps to SOC 2 compliance standards.

## Infrastructure Guardrails

Guardrails are automated rules that prevent non-compliant infrastructure from being provisioned or fix it when drift occurs.

### 1. Shift-Left Security with OPA (Open Policy Agent)
Before infrastructure is deployed, our Terraform code is evaluated against Open Policy Agent (OPA) policies (written in Rego) within our CI pipeline.
*   **Enforced Tagging**: Every resource must have Owner, Environment, and CostCenter tags.
*   **Public Exposure Prevention**: S3 buckets must not have public read/write ACLs. Security Groups must not allow `0.0.0.0/0` on port 22 or databases ports.
*   **Encryption Mandates**: All EBS volumes and RDS instances must have encryption at rest enabled.

### 2. Kubernetes Policy Enforcement (Kyverno / OPA Gatekeeper)
Within EKS, admission controllers enforce policies in real-time.
*   **No Privileged Containers**: Prevents pods from running with root privileges on the host node.
*   **Image Registries**: Pods can only pull images from our approved Elastic Container Registry (ECR).
*   **Resource Quotas**: Enforces CPU and memory limits to prevent noisy neighbor problems.

### 3. AWS Account Guardrails (AWS Organizations & SCPs)
Service Control Policies (SCPs) define the maximum permissions for account members.
*   **Region Restriction**: Prevents creating resources outside of approved regions.
*   **Root User Restriction**: Denies use of the root user account for everyday tasks.
*   **Service Restriction**: Disables unused or unapproved AWS services.

### 4. Continuous Monitoring (AWS Config & Security Hub)
*   **AWS Config**: Continuously monitors and records AWS resource configurations, generating alerts if resources drift from a secure baseline.
*   **Security Hub**: Aggregates security alerts and automates compliance checks against frameworks like CIS AWS Foundations Benchmark.

---

## SOC 2 Compliance Mapping

SOC 2 evaluates security, availability, processing integrity, confidentiality, and privacy. Here is how our architecture addresses these Trust Services Criteria.

### Security
*The system is protected against unauthorized access.*
*   **Edge Auth**: JWT validation via Lambda@Edge drops unauthorized traffic before it reaches the core.
*   **WAF Integration**: Protects against common application-layer attacks.
*   **Least Privilege IAM**: Roles assume specific, minimal permissions needed to function. EKS utilizes IAM Roles for Service Accounts (IRSA).
*   **Vulnerability Scanning**: ECR scans container images on push; GitHub Actions scans code for secrets and vulnerabilities (SAST).

### Availability
*The system is available for operation and use as committed or agreed.*
*   **Multi-AZ EKS**: The core cluster spans multiple Availability Zones, ensuring resilience against data center failures.
*   **Auto-Scaling**: Horizontal Pod Autoscaler (HPA) and Cluster Autoscaler automatically adjust capacity based on load.
*   **CDN (CloudFront)**: Serves content globally, reducing load on origins and providing extreme availability for static assets.
*   **Managed Databases**: RDS and DynamoDB provide automated backups, point-in-time recovery, and Multi-AZ deployments.

### Processing Integrity
*System processing is complete, valid, accurate, timely, and authorized.*
*   **CI/CD Automation**: GitHub Actions ensures all deployments are tested, reviewed, and deployed via a standardized, repeatable process, eliminating manual errors.
*   **Idempotency**: Microservices are designed to be idempotent where possible, ensuring safe retries on network failures.

### Confidentiality & Privacy
*Information is protected as committed or agreed.*
*   **Encryption at Rest**: All RDS databases, DynamoDB tables, and EBS volumes utilize AWS KMS for AES-256 encryption.
*   **Encryption in Transit**: TLS 1.2+ is enforced at the Edge (CloudFront) and between the Load Balancer and EKS cluster. Service Mesh (e.g., Istio) can be utilized for mTLS between pods within EKS.
*   **Data Masking**: PII is masked or tokenized in lower environments and logs.
