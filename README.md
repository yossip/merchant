# B2C Merchant Solution Infrastructure

Welcome to the infrastructure repository for the modern B2C Merchant Solution. This repository defines the foundational architecture, deployment pipelines, and security guardrails necessary to run a highly available, secure, and globally distributed e-commerce platform.

## Architecture Overview

The solution leverages AWS for its robust infrastructure, focusing on edge-optimized delivery, secure microservices, and automated governance.

### High-Level Components

*   **Edge Delivery & Security**: Amazon CloudFront, AWS WAF, and Lambda@Edge provide fast content delivery, edge authentication (JWT verification), and protection against web exploits and DDoS attacks.
*   **Routing**: Amazon Route 53 handles DNS and global routing.
*   **Compute (Core Services)**: Amazon Elastic Kubernetes Service (EKS) hosts the core microservices. We utilize an Application Load Balancer (ALB) as the ingress controller.
*   **Data Tier**: Amazon RDS (for transactional relational data) and Amazon DynamoDB (for high-scale, schema-flexible data like user sessions or product carts).
*   **CI/CD**: GitHub Actions drives automated testing, security scanning, and deployments.
*   **Governance**: Infrastructure as Code (Terraform) heavily utilizes Open Policy Agent (OPA) for configuration checks, augmented by AWS Config and Service Control Policies (SCPs).

### Architecture Diagram

```mermaid
graph TD
    User([End User]) --> DNS[Route 53]
    DNS --> CF[CloudFront Distribution]
    CF --> WAF[AWS WAF]
    CF -- Edge Auth --> LE[Lambda@Edge<br>JWT Validator]
    CF --> ALB[Application Load Balancer]
    ALB --> EKS[Amazon EKS Cluster]
    
    subgraph EKS [EKS Microservices]
        Ingress --> CatalogSVC[Catalog Service]
        Ingress --> CartSVC[Cart Service]
        Ingress --> OrderSVC[Order Service]
    end
    
    CatalogSVC --> DB_RDS[(RDS PostgreSQL)]
    CartSVC --> DB_DDB[(DynamoDB)]
    OrderSVC --> DB_RDS
    
    dev[Developer] --> GitHub[GitHub Actions CI/CD]
    GitHub --> EKS
    GitHub --> AWS_Infra[Terraform IaC]
```

## Repository Structure

```
.
├── .github/
│   └── workflows/                # GitHub Actions definitions for CI/CD pipelines
├── docs/
│   ├── architecture/             # Deep dives into system design and data flow
│   ├── ci_cd/                    # Deployment strategies and rollout processes
│   └── infrastructure/           # Security, compliance (SOC 2), and governance documentation
├── infra/
│   ├── policies/                 # OPA/Rego policies for infrastructure guardrails
│   └── terraform/                # Terraform code orchestrating AWS resources
└── src/
    └── edge-auth/                # Lambda@Edge application code for edge authentication
```

## Getting Started

Refer to the individual documentation sections in `docs/` for deep dives into specific areas of the architecture.

*   [Flow of Operations](docs/architecture/flow_of_operations.md)
*   [Infrastructure Guardrails & SOC 2](docs/infrastructure/guardrails_and_soc2.md)
*   [GitHub Actions & Rollouts](docs/ci_cd/github_actions_rollouts.md)
