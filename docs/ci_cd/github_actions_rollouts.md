# GitHub Actions & Rollout Strategy

A reliable B2C Merchant platform requires a deployment strategy that minimizes downtime and risk while allowing for rapid iteration. We utilize GitHub Actions as our CI/CD orchestrator.

## Continuous Integration (CI)

The CI pipeline runs on every Pull Request to ensure code quality and security before merging.

### Standard Pipeline Steps

1.  **Code Checkout**: Clones the repository.
2.  **Linting & Formatting**: Enforces coding standards (e.g., ESLint, Prettier, Checkov for Terraform).
3.  **Unit & Integration Tests**: Runs tests with coverage requirements.
4.  **Security Scans (Shift-Left)**:
    *   **SAST**: Scans application code for vulnerabilities.
    *   **Secret Scanning**: Checks for accidental commits of API keys or credentials (e.g., using TruffleHog).
    *   **IaC Scanning**: Uses `tfsec` or `Checkov` to ensure Terraform code complies with security best practices.
5.  **Build & Containerize**: Builds the Docker image.
6.  **Container Scanning**: Uses `Trivy` to scan the built image for OS and library vulnerabilities before pushing to the registry.
7.  **Push to Registry**: Pushes the image to Amazon ECR.

## Continuous Deployment (CD)

Our deployment philosophy relies on GitOps principles and progressive rollouts to EKS.

### Deployment Triggers

*   Merges to `main` trigger a deployment to the `staging` environment automatically.
*   Deployments to `production` require a manual approval gate in GitHub Actions or are triggered by tagging a release.

### Rollout Strategies to EKS

While basic `kubectl apply` updates deployments, we utilize progressive delivery tools like **Argo Rollouts** (or native EKS features) to minimize blast radius.

#### 1. Canary Releases (Preferred for Core Services)
When deploying a critical service like the Checkout or Cart API:
*   A new version (Canary) of the service is deployed alongside the old version.
*   The Ingress/Service Mesh initially routes a tiny fraction of traffic (e.g., 5%) to the Canary.
*   The pipeline monitors predefined metrics (e.g., HTTP 5xx rate, latency) for a period.
*   If metrics are stable, traffic is gradually increased (e.g., 20%, 50%, 100%) until the Canary replaces the old version entirely.
*   If metrics spike, an automated rollback occurs immediately.

#### 2. Blue/Green Deployments (Less frequent, major changes)
*   An entirely new duplicate environment (Green) is brought up alongside the live environment (Blue).
*   Tests are run against Green.
*   Traffic is switched instantly at the Load Balancer/Ingress level from Blue to Green.
*   Blue is kept around for a short period for instant rollback if needed.

## Sample GitHub Actions Workflow

Refer to `.github/workflows/production-rollout.yml` in this repository for a concrete example of a pipeline incorporating build, security, infrastructure planning, and manual approval gates.
