# E-commerce Helm charts (learning)

Sample repo for **Argo CD + Helm + ApplicationSet**: https://github.com/jagadish1010/e-commerce-helm

| Doc | Contents |
|---|---|
| [APPLICATIONSET.md](APPLICATIONSET.md) | What we learned: Application vs ApplicationSet vs Project vs app-of-apps, 3-VM lab, every step, UI, gotchas |
| [ARGOCD_SETUP.md](ARGOCD_SETUP.md) | Install Argo CD on one cluster, port-forward UI, first `argocd app create` |
| [examples/README.md](examples/README.md) | Alternate ApplicationSets — do not apply with the live one |

Live GitOps YAML (apply these): `argocd/ecommerce-appset-clusters.yaml`, optional `argocd/ecommerce-project.yaml`. Optional bootstrap: `bootstrap/root-app.yaml`.

---

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
