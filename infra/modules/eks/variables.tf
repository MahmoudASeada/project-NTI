variable "name" {
  description = "Cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. null = the default version chosen by AWS"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and the nodes"
  type        = list(string)
}

variable "admin_principal_arns" {
  description = "IAM users/roles that get cluster-admin (ARNs of the user or role, not of an assumed-role session)"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Keep the API endpoint reachable from the internet (needed for kubectl and for the GitHub runners that run Helm)"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Who may reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "node_disk_size" {
  description = "Root volume size (GiB) of each node"
  type        = number
  default     = 30
}
