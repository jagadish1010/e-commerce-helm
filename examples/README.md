# Reference only - do not apply

These ApplicationSets are alternative designs kept for learning. Argo CD does not
sync this folder. Three of them would collide if applied together: all generate
`payments-dev` / `shipping-dev`, and two share the name `ecommerce`.

| File | Design |
|---|---|
| `ecommerce-appset.yaml` | matrix of services x envs, single cluster, dev/qa as namespaces |
| `ecommerce-appset-dev.yaml` | list of services, dev only, single cluster |
| `ecommerce-appset-multicluster.yaml` | matrix of services x envs, cluster URLs hard-coded |

The live setup is `argocd/ecommerce-appset-clusters.yaml`, which discovers clusters
by their `ecommerce=true` and `env=<name>` labels instead of hard-coding URLs.
