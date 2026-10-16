terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

  # The bucket name is NOT hardcoded: the pipeline passes it from the
  # TF_STATE_BUCKET variable (terraform init -backend-config="bucket=...").
  backend "s3" {
    key          = "prod/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true # state locking directly in S3 (no DynamoDB needed)
  }
}
