# environments/integration/01-core-eks.tfvars
aws_region  = "us-east-1"
environment = "integration"

eks_version = "1.30"

# Intermediate capacity for integration testing
core_on_demand_min_size     = 1
core_on_demand_max_size     = 3
core_on_demand_desired_size = 2

spot_workers_min_size     = 2
spot_workers_max_size     = 5
spot_workers_desired_size = 3

ingress_nodes_min_size     = 1
ingress_nodes_max_size     = 3
ingress_nodes_desired_size = 2

devops_tools_nodes_min_size     = 1
devops_tools_nodes_max_size     = 2
devops_tools_nodes_desired_size = 1
