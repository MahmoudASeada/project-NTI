variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "cluster_name" {
  type    = string
  default = "taskboard-prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "kubernetes_version" {
  description = "null = default version chosen by AWS"
  type        = string
  default     = null
}

variable "eks_admin_principal_arns" {
  description = "IAM users/roles that get cluster-admin on the cluster"
  type        = list(string)
}
variable "github_repository" {
  description = "owner/repo of the GitHub repository, e.g. MahmoudASeada/project-NTI"
  type        = string
}
