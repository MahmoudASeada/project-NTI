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