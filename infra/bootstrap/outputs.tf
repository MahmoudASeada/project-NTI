output "state_bucket" {
  description = "Use as TF_STATE_BUCKET (GitHub variable) and in the S3 backend config"
  value       = aws_s3_bucket.tfstate.bucket
}

output "infra_role_arn" {
  description = "Use as AWS_INFRA_ROLE_ARN (GitHub variable)"
  value       = aws_iam_role.github_infra.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (reused by the githuboidc-role module)"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "region" {
  value = var.region
}
