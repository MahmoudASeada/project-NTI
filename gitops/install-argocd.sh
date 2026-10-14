#!/usr/bin/env bash
set -euo pipefail

APP_FILE="${1:?usage: install-argocd.sh <application-file>}"

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update argo

helm upgrade --install argocd argo/argo-cd \
  -n argocd --create-namespace --wait --timeout 10m

kubectl apply -f "$APP_FILE"
echo "Argo CD installed and Application applied: $APP_FILE"