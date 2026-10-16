provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "taskboard"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}

module "network" {
  source = "../../modules/network"

  name         = var.cluster_name
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
}