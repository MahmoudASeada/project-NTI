variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "secret_arns" {
  description = "Secrets Manager secrets the External Secrets Operator may read"
  type        = list(string)
}

variable "lbc_chart_version" {
  description = "Helm chart version of aws-load-balancer-controller (pinned)"
  type        = string
}

variable "eso_chart_version" {
  description = "Helm chart version of external-secrets (pinned)"
  type        = string
}