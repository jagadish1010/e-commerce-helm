# E-commerce Helm charts (learning)

One `values.yaml` per chart. Environment is chosen with `env`, like `cs-service-apikey`.

```text
values.yaml
  env: dev          ← pick this
  config: ...       ← defaults
  dev: / qa: / stage: / prod:   ← overlays merged into config
```

```bash
cd /Users/jhatti/Documents/Demo_Projects/helm_learnings/e_commerce

# see rendered YAML without installing
helm template payments ./payments --set env=dev
helm template payments ./payments --set env=prod
```

## Install

```bash
# dev (default env: dev, --set is optional)
helm upgrade --install payments ./payments -n ecommerce-dev --create-namespace --set env=dev
helm upgrade --install shipping ./shipping -n ecommerce-dev --create-namespace --set env=dev

helm upgrade --install payments ./payments -n ecommerce-qa --create-namespace --set env=qa
helm upgrade --install shipping ./shipping -n ecommerce-qa --create-namespace --set env=qa

helm upgrade --install payments ./payments -n ecommerce-stage --create-namespace --set env=stage
helm upgrade --install shipping ./shipping -n ecommerce-stage --create-namespace --set env=stage

helm upgrade --install payments ./payments -n ecommerce-prod --create-namespace --set env=prod
helm upgrade --install shipping ./shipping -n ecommerce-prod --create-namespace --set env=prod
```

```bash
kubectl get deploy,svc,hpa,ingress,sa -n ecommerce-dev
kubectl get pods -n ecommerce-dev --show-labels   # env=dev
```
