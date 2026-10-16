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
module "ecr" {
  source = "../../modules/ecr"

  name = "taskboard-backend"
}
data "aws_caller_identity" "current" {}

locals {
  # The pipeline role must be cluster-admin too: Terraform installs Helm charts into the cluster
  infra_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/taskboard-github-infra"
}

module "eks" {
  source = "../../modules/eks"

  name                 = var.cluster_name
  kubernetes_version   = var.kubernetes_version
  subnet_ids           = module.network.private_subnet_ids
  admin_principal_arns = distinct(concat(var.eks_admin_principal_arns, [local.infra_role_arn]))
}
# Shared secret between CloudFront (sends it) and the ALB (requires it)
resource "random_password" "origin_verify" {
  length  = 32
  special = false
}

module "backend_alb" {
  source = "../../modules/backend-alb"

  name                 = var.cluster_name
  vpc_id               = module.network.vpc_id
  vpc_cidr             = module.network.vpc_cidr
  public_subnet_ids    = module.network.public_subnet_ids
  origin_verify_secret = random_password.origin_verify.result
}

# ALB -> backend pods on port 8000 (pods use the nodes' security group)
resource "aws_vpc_security_group_ingress_rule" "alb_to_pods" {
  security_group_id            = module.eks.cluster_security_group_id
  referenced_security_group_id = module.backend_alb.security_group_id
  description                  = "ALB to backend pods"
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}
module "static_site" {
  source = "../../modules/static-site"

  name                 = var.cluster_name
  alb_dns_name         = module.backend_alb.dns_name
  origin_verify_secret = random_password.origin_verify.result
}
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com" # created in bootstrap
}

# Least privilege: push to THIS ECR repo, write to THIS bucket, invalidate THIS distribution
data "aws_iam_policy_document" "deploy" {
  statement {
    sid       = "EcrLogin"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # this action cannot be scoped to a repository
  }

  statement {
    sid = "EcrPushAndPromote"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
    ]
    resources = [module.ecr.repository_arn]
  }

  statement {
    sid       = "FrontendBucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${module.static_site.bucket_name}"]
  }

  statement {
    sid       = "FrontendBucketWrite"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${module.static_site.bucket_name}/*"]
  }

  statement {
    sid       = "InvalidateCloudFront"
    actions   = ["cloudfront:CreateInvalidation", "cloudfront:GetInvalidation"]
    resources = [module.static_site.distribution_arn]
  }
}

module "github_deploy_role" {
  source = "../../modules/github-oidc-role"

  name              = "${var.cluster_name}-github-deploy"
  oidc_provider_arn = data.aws_iam_openid_connect_provider.github.arn
  policy_json       = data.aws_iam_policy_document.deploy.json

  subjects = [
    "repo:${var.github_repository}:ref:refs/heads/main",    # backend build + push on main
    "repo:${var.github_repository}:ref:refs/tags/v*",       # release: promote the image
    "repo:${var.github_repository}:environment:production", # release: deploy the frontend
  ]
}
resource "random_password" "db" {
  length  = 32
  special = false # avoids quoting problems in connection strings
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.cluster_name}/db-password"

  # 0 = delete immediately. We destroy and recreate the stack often; with the
  # default 7-30 days the name stays reserved and the next apply would fail.
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
# Helm talks to the cluster that this same Terraform code creates
provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}

module "platform" {
  source = "../../modules/platform"

  cluster_name      = module.eks.cluster_name
  region            = var.region
  vpc_id            = module.network.vpc_id
  secret_arns       = [aws_secretsmanager_secret.db.arn]
  lbc_chart_version = "3.6.0"
  eso_chart_version = "2.13.0"

  # Wait for the whole cluster: nodes AND add-ons (Pod Identity agent, CoreDNS...)
  depends_on = [module.eks]
}
