variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. development, integration, staging, production)"
  type        = string
}

variable "eks_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.30"
}

variable "core_on_demand_min_size" {
  description = "Minimum size of the core on-demand node group"
  type        = number
  default     = 1
}

variable "core_on_demand_max_size" {
  description = "Maximum size of the core on-demand node group"
  type        = number
  default     = 5
}

variable "core_on_demand_desired_size" {
  description = "Desired size of the core on-demand node group"
  type        = number
  default     = 2
}

variable "spot_workers_min_size" {
  description = "Minimum size of the spot workers node group"
  type        = number
  default     = 3
}

variable "spot_workers_max_size" {
  description = "Maximum size of the spot workers node group"
  type        = number
  default     = 20
}

variable "spot_workers_desired_size" {
  description = "Desired size of the spot workers node group"
  type        = number
  default     = 8
}

variable "ingress_nodes_min_size" {
  description = "Minimum size of the ingress node group"
  type        = number
  default     = 2
}

variable "ingress_nodes_max_size" {
  description = "Maximum size of the ingress node group"
  type        = number
  default     = 5
}

variable "ingress_nodes_desired_size" {
  description = "Desired size of the ingress node group"
  type        = number
  default     = 2
}

variable "devops_tools_nodes_min_size" {
  description = "Minimum size of the devops tools node group"
  type        = number
  default     = 1
}

variable "devops_tools_nodes_max_size" {
  description = "Maximum size of the devops tools node group"
  type        = number
  default     = 5
}

variable "devops_tools_nodes_desired_size" {
  description = "Desired size of the devops tools node group"
  type        = number
  default     = 1
}
