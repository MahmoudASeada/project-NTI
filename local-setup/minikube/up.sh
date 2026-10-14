#!/usr/bin/env bash
set -euo pipefail

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

echo "==> Deploying with Helm"
helm upgrade --install taskboard "$CHART" \
  -n "$NS" --create-namespace \
  -f "$CHART/values-local.yaml" \
  --wait --timeout 5m

echo "==> Running helm test"
helm test taskboard -n "$NS" --logs