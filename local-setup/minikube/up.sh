#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-helm}"     # helm (default) | argocd

cd "$(dirname "$0")"
ROOT="$(cd ../.. && pwd)"
CHART="$ROOT/deploy/helm/taskboard"
PROFILE=taskboard
NS=taskboard
IMAGE=taskboard-backend:local

echo "==> Starting minikube profile '$PROFILE' (if needed)"
if ! minikube status -p "$PROFILE" >/dev/null 2>&1; then
  minikube start -p "$PROFILE" --cpus 2 --memory 4096
fi
kubectl config use-context "$PROFILE"

echo "==> Building backend image"
docker build --pull -t "$IMAGE" --build-arg APP_VERSION=local "$ROOT/app/backend"

echo "==> Loading image into minikube"
minikube -p "$PROFILE" image load --overwrite "$IMAGE"

if [ "$MODE" = "argocd" ]; then
  echo "==> Installing Argo CD and the taskboard Application"
  "$ROOT/gitops/install-argocd.sh" "$ROOT/gitops/applications/taskboard-local.yaml"

  echo "==> Waiting for Argo CD to deploy taskboard"
  until kubectl -n "$NS" get deploy taskboard-backend >/dev/null 2>&1; do sleep 5; done
  kubectl -n "$NS" rollout status deploy/taskboard-backend --timeout=5m
  kubectl -n "$NS" rollout status statefulset/taskboard-postgres --timeout=5m
  echo "Argo CD deployed the app. UI: kubectl -n argocd port-forward svc/argocd-server 8080:443"
else
  echo "==> Deploying with Helm"
  helm upgrade --install taskboard "$CHART" \
    -n "$NS" --create-namespace \
    -f "$CHART/values-local.yaml" \
    --wait --timeout 5m

  echo "==> Running helm test"
  helm test taskboard -n "$NS" --logs
fi