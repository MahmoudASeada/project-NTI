terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

# Trust policy shared by both roles: only EKS Pod Identity may assume them
data "aws_iam_policy_document" "pods_assume" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller (registers backend pods in the ALB target group)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "lbc" {
  name               = "${var.cluster_name}-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.pods_assume.json
}

# Official policy published by the controller project (must match the controller version)
resource "aws_iam_role_policy" "lbc" {
  name   = "${var.cluster_name}-lbc-policy"
  role   = aws_iam_role.lbc.id
  policy = file("${path.module}/lbc-iam-policy.json")
}

resource "aws_eks_pod_identity_association" "lbc" {
  cluster_name    = var.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lbc.arn
}

resource "helm_release" "lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lbc_chart_version
  namespace  = "kube-system"
  timeout    = 600

  values = [yamlencode({
    clusterName  = var.cluster_name
    region       = var.region
    vpcId        = var.vpc_id
    replicaCount = 1 # two small nodes: keep the pod count low
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
    }
  })]

  # The Pod Identity association must exist BEFORE the pods start,
  # otherwise they do not get AWS credentials injected.
  depends_on = [aws_eks_pod_identity_association.lbc]
}

# ---------------------------------------------------------------------------
# External Secrets Operator (copies the DB password from Secrets Manager)
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "eso" {
  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secret_arns # only the secrets we list, nothing else
  }
}

resource "aws_iam_role" "eso" {
  name               = "${var.cluster_name}-eso-role"
  assume_role_policy = data.aws_iam_policy_document.pods_assume.json
}

resource "aws_iam_role_policy" "eso" {
  name   = "${var.cluster_name}-eso-policy"
  role   = aws_iam_role.eso.id
  policy = data.aws_iam_policy_document.eso.json
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = var.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.eso.arn
}

resource "helm_release" "eso" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.eso_chart_version
  namespace        = "external-secrets"
  create_namespace = true
  timeout          = 600

  values = [yamlencode({
    installCRDs = true
    serviceAccount = {
      create = true
      name   = "external-secrets"
    }
  })]

  depends_on = [aws_eks_pod_identity_association.eso]
}
