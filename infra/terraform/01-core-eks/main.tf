terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # backend "s3" { key = "01-core-eks/terraform.tfstate" ... } 
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project      = "B2C-Merchant"
      Environment  = var.environment
      ManagedBy    = "Terraform"
      StateStage   = "01-core-eks"
      
      # AWS EDP / Cost Allocation Tags
      CostCenter   = "CC-12345"
      BusinessUnit = "E-Commerce"
      Owner        = "Platform-Engineering"
      Application  = "Merchant-Core"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "merchant-core-cluster-${var.environment}"
  cluster_version = var.eks_version

  # ---------------------------------------------------------
  # High Availability: Ensuring Multi-AZ Distribution
  # ---------------------------------------------------------
  # Assumption: A VPC module or existing VPC is managed elsewhere.
  # By explicitly passing subnets that span at least 3 distinct Availability Zones,
  # the EKS control plane and managed node groups are automatically distributed 
  # highly-available across the AWS Region.
  
  # vpc_id                   = data.aws_vpc.selected.id
  # subnet_ids               = data.aws_subnets.private.ids       # Nodes in at least 3 AZs (e.g. us-east-1a, 1b, 1c)
  # control_plane_subnet_ids = data.aws_subnets.intra.ids         # EKS ENIs in at least 3 AZs

  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["x.x.x.x/32"]

  enable_irsa = true

  cluster_addons = {
    coredns = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni = { most_recent = true }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }

  eks_managed_node_groups = {
    core_on_demand = {
      instance_types = ["m6i.large", "m5.large"]
      min_size       = var.core_on_demand_min_size
      max_size       = var.core_on_demand_max_size
      desired_size   = var.core_on_demand_desired_size
      capacity_type  = "ON_DEMAND"
    }
    spot_workers = {
      instance_types = ["m6i.large", "m5.large", "m6a.large", "m5a.large"]
      min_size       = var.spot_workers_min_size
      max_size       = var.spot_workers_max_size
      desired_size   = var.spot_workers_desired_size
      capacity_type  = "SPOT"
      taints = [
        {
          key    = "spotInstance"
          value  = "true"
          effect = "PREFER_NO_SCHEDULE"
        }
      ]
    }
    ingress_nodes = {
      instance_types = ["m5.large"]
      min_size       = var.ingress_nodes_min_size
      max_size       = var.ingress_nodes_max_size
      desired_size   = var.ingress_nodes_desired_size
      capacity_type  = "ON_DEMAND"
      labels = { role = "ingress" }
      taints = [
        {
          key    = "role"
          value  = "ingress"
          effect = "NO_SCHEDULE"
        }
      ]
    }
    devops_tools_nodes = {
      instance_types = ["t3.large", "t3.xlarge"]
      min_size       = var.devops_tools_nodes_min_size
      max_size       = var.devops_tools_nodes_max_size
      desired_size   = var.devops_tools_nodes_desired_size
      capacity_type  = "ON_DEMAND"
      labels = { role = "devops-tools" }
    }
  }

  cluster_identity_providers = {
    amazon_oidc = {
      client_id = "sts.amazonaws.com"
      issuer_url = "https://oidc.eks.${var.aws_region}.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
    }
  }
}

module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name             = "ebs-csi-driver-role-${var.environment}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
