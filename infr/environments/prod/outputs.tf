output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}
output "ecr_repository_url" {
  value = module.ecr.repository_url
}
output "alb_dns_name" {
  value = module.backend_alb.dns_name
}

output "backend_target_group_arn" {
  description = "Goes into values-prod.yaml (backend_target_group_arn)"
  value       = module.backend_alb.target_group_arn
}
output "frontend_bucket" {
  value = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
  value = module.static_site.distribution_id
}

output "app_url" {
  value = module.static_site.app_url
}
output "github_deploy_role_arn" {
  description = "Goes into the AWS_DEPLOY_ROLE_ARN GitHub variable"
  value       = module.github_deploy_role.role_arn
}
output "db_secret_name" {
  description = "Goes into values-prod.yaml (the ExternalSecret reads this key)"
  value       = aws_secretsmanager_secret.db.name
}