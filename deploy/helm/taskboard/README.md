# taskboard Helm chart

Deploys the TaskBoard backend (Deployment) and PostgreSQL (StatefulSet + PVC).

```bash
helm lint . -f values-local.yaml
helm template taskboard . -f values-local.yaml
helm upgrade --install taskboard . -n taskboard --create-namespace -f values-local.yaml --wait
helm test taskboard -n taskboard --logs
```

| Values file | Use |
|---|---|
| values-local.yaml | minikube: plain Secret, local image |
| values-prod.yaml | EKS: ECR image, ExternalSecret, TargetGroupBinding |
