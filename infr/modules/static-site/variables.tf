variable "name" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the backend ALB (origin of /api/*)"
  type        = string
}

variable "origin_verify_secret" {
  description = "Secret header value the ALB requires; CloudFront adds it to every request to the ALB"
  type        = string
  sensitive   = true
}