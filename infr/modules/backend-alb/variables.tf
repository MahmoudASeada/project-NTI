variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  description = "Pods live inside the VPC; the ALB may only send traffic there"
  type        = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "origin_verify_secret" {
  description = "Value of the X-Origin-Verify header that only our CloudFront sends"
  type        = string
  sensitive   = true
}

variable "target_port" {
  type    = number
  default = 8000
}

variable "health_check_path" {
  type    = string
  default = "/api/health/ready"
}