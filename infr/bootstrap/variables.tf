variable "region" {
  description = "AWS region for everything in this project"
  type        = string
  default     = "eu-west-1"
}

variable "github_owner" {
  description = "GitHub username (or organization) that owns the taskboard repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "taskboard"
}

variable "state_bucket_prefix" {
  description = "Prefix of the Terraform state bucket (account id and region are appended to make it globally unique)"
  type        = string
  default     = "taskboard-tfstate"
}