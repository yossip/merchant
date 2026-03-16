# environments/staging/01-core-eks.tfvars
aws_region  = "us-east-1"
environment = "staging"

eks_version = "1.30"

# Production-like capacity
core_on_demand_min_size     = 2
core_on_demand_max_size     = 5
core_on_demand_desired_size = 2

spot_workers_min_size     = 3
spot_workers_max_size     = 10
spot_workers_desired_size = 5

ingress_nodes_min_size     = 2
ingress_nodes_max_size     = 5
ingress_nodes_desired_size = 2

devops_tools_nodes_min_size     = 1
devops_tools_nodes_max_size     = 3
devops_tools_nodes_desired_size = 1
