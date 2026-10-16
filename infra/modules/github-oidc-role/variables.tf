variable "name" {
  description = "IAM role name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (created in bootstrap)"
  type        = string
}

variable "subjects" {
  description = "Allowed OIDC 'sub' claims, e.g. repo:owner/repo:environment:production (wildcards allowed)"
  type        = list(string)
}

variable "policy_json" {
  description = "The permissions of the role (an IAM policy document in JSON)"
  type        = string
}
