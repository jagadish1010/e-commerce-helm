# Argo CD setup (end to end)

This is the full path we used: install Argo CD **on the Kubernetes cluster**, install the **CLI on the Mac**, put these Helm charts on **GitHub**, then create Applications so Argo CD syncs them.

Important: Argo CD is **not** an app that runs on the Mac. The **server** runs as pods in the cluster. The Mac only has `kubectl`, the `argocd` CLI, and a browser. The UI at `https://localhost:8080` is a **port-forward** into the `argocd-server` pod.

| Piece | Where it lives |
|---|---|
| Kubernetes (k3s) | VM `ci-cs-jhatti-helm-learning` (`10.196.102.210`) |
| Cluster API URL | `https://ci-cs-jhatti-helm-learning-k8s.cloudinsights-dev.netapp.com:443` |
| Argo CD pods | namespace `argocd` on that cluster |
| Helm charts | this folder: `payments/`, `shipping/` |
| Git | `https://github.com/jagadish1010/e-commerce-helm.git` |
| Mac kubeconfig | `~/.kube/config-helm-learning` |

Do **not** commit kubeconfig files (`dev_vm_kubeconfig.yaml`).

---

## 1. Point kubectl at the cluster (Mac)

Copy kubeconfig from the VM. On these k3s lab machines it is usually `/etc/k3s/kubeconfig` or `~/.kube/config`.

```bash
scp jhatti@10.196.102.210:.kube/config ~/.kube/config-helm-learning
chmod 600 ~/.kube/config-helm-learning
export KUBECONFIG=$HOME/.kube/config-helm-learning
kubectl get nodes
```

Expected node:

```text
ci-cs-jhatti-helm-learning   Ready   control-plane,master,worker   v1.35.0+k3s1
```

`server:` in that kubeconfig should be:

```text
https://ci-cs-jhatti-helm-learning-k8s.cloudinsights-dev.netapp.com:443
```

If it still says `127.0.0.1:6443`, kubectl from the Mac will fail. The lab DNS name on port **443** is what works from the Mac. Port **6443** and NodePorts were blocked or reset on the network path.

Keep using `export KUBECONFIG=$HOME/.kube/config-helm-learning` in every Mac terminal so you do not hit the default AWS EKS context in `~/.kube/config`.

---

## 2. Install Argo CD on the cluster (not on the Mac)

Run these with kubectl pointed at the helm-learning cluster (Mac or VM):

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
```

Wait until `argocd-server`, `argocd-repo-server`, `argocd-application-controller`, and redis are Running.

The UI process is the **`argocd-server`** pod. The Service is ClusterIP (`80` and `443`). There is no Ingress, so there is no public Argo CD URL unless you add one later.

---

## 3. Install the Argo CD CLI on the Mac

This is only the command-line client.

```bash
brew install argocd
argocd version --client
```

---

## 4. Get the admin password

```bash
export KUBECONFIG=$HOME/.kube/config-helm-learning
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

- Username: `admin`
- Password: the printed value

If you already changed the password in the UI or with `argocd account update-password`, this secret is only the **original** password.

---

## 5. Open the UI (`https://localhost:8080`)

### What works (use this)

On the **Mac**, with the helm-learning kubeconfig:

```bash
export KUBECONFIG=$HOME/.kube/config-helm-learning
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Leave that terminal open. In the browser: **https://localhost:8080** (accept the self-signed cert). Applications page: **https://localhost:8080/applications**.

`8080:443` means: listen on the Mac’s port 8080, send traffic to the Service’s HTTPS port 443, which goes to the `argocd-server` pod.

In a **second** Mac terminal (port-forward still running):

```bash
argocd login localhost:8080 --username admin --insecure
```

`argocd login localhost:8080` must run on the **same machine** as port-forward. If port-forward is on the Mac, do not run login on the VM.

### What we tried and why it failed

**Port-forward on the VM, browser on the Mac**  
`localhost` in Chrome is the Mac. The forward was on the VM → connection refused.

**SSH tunnel** (temporary workaround)

```bash
ssh -L 8080:127.0.0.1:8080 jhatti@10.196.102.210
```

That maps Mac:8080 → VM:8080 (where the VM port-forward was listening). The VM login shell is `csh`, so bash `export` in profiles printed errors; the tunnel still worked. You do **not** need this if port-forward runs on the Mac.

**NodePort**

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
# example: 80:30276/TCP, 443:30371/TCP
```

TCP to `10.196.102.210:30371` connected then **reset**. High ports are blocked on the Mac-to-lab path. SSH (22) and the cluster API hostname (443) work. Optional revert:

```bash
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"ClusterIP"}}'
```

**Port already in use / connection reset**  
An old `ssh -L` process can keep holding Mac port 8080 after the VM forward dies. That produces `address already in use` or `ERR_CONNECTION_RESET`. Find and kill it:

```bash
lsof -nP -iTCP:8080 -sTCP:LISTEN
kill <pid>
```

Then start Mac port-forward again. If 8080 is busy, use `8081:443` and open `https://localhost:8081`.

---

## 6. Create the GitHub repo and push this folder

Argo CD cannot read `/Users/jhatti/Documents/Demo_Projects/helm_learnings/e_commerce` on your Mac. It clones Git.

Repo we used: **https://github.com/jagadish1010/e-commerce-helm**

On the Mac:

```bash
cd /Users/jhatti/Documents/Demo_Projects/helm_learnings/e_commerce

# ignore secrets and packaged charts
cat > .gitignore << 'EOF'
dev_vm_kubeconfig.yaml
*.tgz
.DS_Store
.idea/
EOF

git init
git branch -M main
git add payments shipping README.md .gitignore
git commit -m "Add payments and shipping Helm charts"
```

Create an **empty** repo on GitHub named `e-commerce-helm` (no README), then:

```bash
git remote add origin https://github.com/jagadish1010/e-commerce-helm.git
# if origin already exists:
# git remote set-url origin https://github.com/jagadish1010/e-commerce-helm.git
git push -u origin main
```

GitHub **does not accept your account password** for `git push`. Use a [Personal Access Token](https://github.com/settings/tokens) (classic token needs `repo` scope) as the password, or:

```bash
gh auth login
git push -u origin main
```

Confirm the repo **root** has `payments/` and `shipping/` (not nested under another `e_commerce/` folder).

---

## 7. Create Argo CD Applications (sync the charts)

Port-forward + `argocd login` must already work.

```bash
argocd app create payments-dev \
  --repo https://github.com/jagadish1010/e-commerce-helm.git \
  --path payments \
  --revision HEAD \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce-dev \
  --helm-set env=dev \
  --sync-option CreateNamespace=true \
  --sync-policy automated \
  --auto-prune --self-heal

argocd app create shipping-dev \
  --repo https://github.com/jagadish1010/e-commerce-helm.git \
  --path shipping \
  --revision HEAD \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace ecommerce-dev \
  --helm-set env=dev \
  --sync-option CreateNamespace=true \
  --sync-policy automated \
  --auto-prune --self-heal
```

If the repo is **private**, register it first:

```bash
argocd repo add https://github.com/jagadish1010/e-commerce-helm.git \
  --username jagadish1010 --password <github-pat>
```

### What the flags mean

| Flag | Meaning |
|---|---|
| `--repo` | Git URL Argo CD clones |
| `--path payments` / `shipping` | Helm chart directory in that repo |
| `--revision HEAD` | Latest commit on the default branch |
| `--helm-set env=dev` | Same as `helm ... --set env=dev` |
| `--dest-server https://kubernetes.default.svc` | Install on **this** cluster (where Argo CD runs) |
| `--dest-namespace ecommerce-dev` | Target namespace (created if needed) |
| `--sync-option CreateNamespace=true` | Create `ecommerce-dev` if missing |
| `--sync-policy automated` | Apply Git changes without clicking Sync |
| `--auto-prune` | Delete cluster objects that were removed from Git |
| `--self-heal` | Revert manual `kubectl` edits back to what Git says |

You can create the same apps in the UI: **New App** → same repo, path, namespace, Helm parameter `env=dev`.

---

## 8. Verify

```bash
argocd app get payments-dev
argocd app get shipping-dev
kubectl get deploy,svc,pods -n ecommerce-dev
```

UI: Applications should show **Synced** / **Healthy**. Charts use `nginx` as a placeholder image.

---

## Day to day

1. Edit a chart under `payments/` or `shipping/`.
2. `git add` / `commit` / `git push origin main`.
3. Argo CD (automated sync) applies it. Do not `helm upgrade` those releases unless you are debugging.

If you want to experiment with `kubectl` without being overwritten, recreate the app without `--self-heal`.

---

## Quick reference (every session)

```bash
export KUBECONFIG=$HOME/.kube/config-helm-learning
kubectl get nodes
kubectl port-forward svc/argocd-server -n argocd 8080:443
# other terminal:
argocd login localhost:8080 --username admin --insecure
# browser: https://localhost:8080
```
