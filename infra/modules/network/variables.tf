variable "name" {
  description = "Name prefix for all network resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used in subnet tags so Kubernetes can discover the subnets"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}
