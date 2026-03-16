# environments/production/01-core-eks.tfvars
aws_region  = "us-east-1"
environment = "production"

eks_version = "1.30"

# Full scale capacity for production
core_on_demand_min_size     = 3
core_on_demand_max_size     = 10
core_on_demand_desired_size = 3

spot_workers_min_size     = 5
spot_workers_max_size     = 50
spot_workers_desired_size = 15

ingress_nodes_min_size     = 3
ingress_nodes_max_size     = 10
ingress_nodes_desired_size = 3

devops_tools_nodes_min_size     = 1
devops_tools_nodes_max_size     = 5
devops_tools_nodes_desired_size = 2
