variable "name" {
  description = "ECR repository name"
  type        = string
}

variable "max_image_count" {
  description = "How many images to keep before the oldest are expired"
  type        = number
  default     = 20
}