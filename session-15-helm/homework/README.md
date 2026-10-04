# Session 15 — Helm (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | Helm commands — create, install, list, status, get, upgrade, history, rollback, uninstall, repo, search | ✅ |
| 2 | Rollback workflow — Install → Upgrade → Verify → Upgrade → Verify → Rollback → Verify | ✅ |
| 3 | Mini project — Notes App with `notes-chart` | ✅ |

All commands are run from the `session-15-helm/` folder.

## 1. Helm Commands

### Create a chart
```bash
helm create homework/demo-app
helm lint homework/demo-app
helm template demo homework/demo-app
```
`helm create` scaffolds `Chart.yaml`, `values.yaml` and `templates/`; `lint`/`template` check and render it without a cluster.

![helm create, lint and template output](../screenshots/helm-create.png)

### Repo & search
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm repo list
helm search repo nginx
```
![Bitnami repo added and nginx charts found](../screenshots/helm-repo-search.png)

### Install, list, status, get
```bash
helm install demo homework/demo-app
helm list
helm status demo
helm get values demo --all
helm get manifest demo
```
![Release installed and inspected](../screenshots/helm-install-status.png)

### Upgrade, history, rollback, uninstall
```bash
helm upgrade demo homework/demo-app --set replicaCount=2
helm history demo
helm rollback demo 1
helm history demo
helm uninstall demo
helm list
```
![Upgrade, history, rollback and uninstall](../screenshots/helm-upgrade-rollback.png)

## 2. Rollback Workflow

Chart: `07-install-upgrade/app-chart` (defaults: 1 replica, `nginx:1.24`).

### Install → Upgrade → Verify
```bash
helm install web-app 07-install-upgrade/app-chart
helm upgrade web-app 07-install-upgrade/app-chart --set replicaCount=3
helm get values web-app
kubectl get deploy web-app-app -o wide
```
Revision 2 → 3 replicas of `nginx:1.24`.

![Revision 2: 3 replicas running](../screenshots/rollback-upgrade-1.png)

### Upgrade again → Verify
```bash
helm upgrade web-app 07-install-upgrade/app-chart --set replicaCount=3 --set image.tag=1.25
helm get values web-app
kubectl get deploy web-app-app -o wide
```
Revision 3 → image changed to `nginx:1.25`.

![Revision 3: image nginx:1.25](../screenshots/rollback-upgrade-2.png)

### Rollback → Verify
```bash
helm rollback web-app 2
helm history web-app
helm get values web-app
kubectl get deploy web-app-app -o wide
```
Rollback creates revision 4 ("Rollback to 2") — back to `nginx:1.24`, 3 replicas. History is kept, not deleted.

![Rolled back to revision 2](../screenshots/rollback-verify.png)

## 3. Mini Project — Notes App

Chart: `mini-project/notes-chart` (ConfigMap + Deployment + NodePort Service).

```bash
helm lint mini-project/notes-chart
helm install notes-dev mini-project/notes-chart
kubectl get pods,svc,configmap
```
![notes-dev installed (1 replica, development)](../screenshots/mini-install.png)

```bash
helm upgrade notes-dev mini-project/notes-chart -f mini-project/notes-chart/values-prod.yaml
kubectl get pods
helm history notes-dev
```
![Upgraded to prod values — 3 replicas](../screenshots/mini-upgrade.png)

```bash
helm upgrade notes-dev mini-project/notes-chart --set image.tag=broken-tag-does-not-exist
kubectl get pods
helm rollback notes-dev 2
kubectl get pods
helm history notes-dev
```
Bad image tag → `ImagePullBackOff`; rollback to revision 2 restores healthy pods.

![Bad upgrade and rollback to revision 2](../screenshots/mini-rollback.png)

## Cleanup
```bash
helm uninstall web-app notes-dev
helm list
```
