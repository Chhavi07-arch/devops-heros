# Session 20 — Monitoring, Observability & GitOps (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | Monitoring — metrics, logs, alerts, CPU, memory, app health (Prometheus + Grafana) | ✅ |
| 2 | Observability — metrics, logs, traces | ✅ |
| 3 | GitOps — Argo CD syncing from my fork, auto-sync + self-heal | ✅ |

## Folder Guide

| Path | Covers |
|---|---|
| [`homework/monitoring/demo-app.yaml`](homework/monitoring/demo-app.yaml) | nginx app with probes + limits, and a `cpu-burner` pod |
| [`homework/monitoring/alert-rules.yaml`](homework/monitoring/alert-rules.yaml) | `PrometheusRule`: `HighPodCPU`, `PodRestarting` |
| [`homework/gitops-app/`](homework/gitops-app/) | Manifests Argo CD watches in Git |
| [`homework/argocd-application.yaml`](homework/argocd-application.yaml) | Argo CD `Application` (repo = my fork, `main`) |

Cluster: minikube on macOS.

---

## Task 1 — Monitoring

### 1. Install kube-prometheus-stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace
kubectl get pods -n monitoring
```
![Prometheus, Grafana, Alertmanager pods running](screenshots/monitoring-pods.png)

### 2. App health — probes
```bash
cd session20-monitoring-observability-gitops/homework
kubectl apply -f monitoring/demo-app.yaml
kubectl get pods -n chhavi-demo
kubectl describe pod -n chhavi-demo -l app=chhavi-web | grep -E "Liveness|Readiness"
```
![Pods Ready with liveness/readiness probes](screenshots/app-health.png)

### 3. Logs
```bash
kubectl logs -n chhavi-demo deploy/cpu-burner --tail=5
```
![Container logs](screenshots/logs.png)

### 4. Metrics — CPU & memory in Prometheus
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```
At http://localhost:9090 run:
```promql
sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="chhavi-demo", container!=""}[2m]))
sum by (pod) (container_memory_working_set_bytes{namespace="chhavi-demo", container!=""})
```
![CPU usage per pod](screenshots/prometheus-cpu.png)
![Memory usage per pod](screenshots/prometheus-memory.png)

### 5. Alert rule
```bash
kubectl apply -f monitoring/alert-rules.yaml
```
`cpu-burner` pushes CPU above 0.1 core, so `HighPodCPU` goes Pending → Firing (Prometheus → Alerts).

![HighPodCPU alert firing](screenshots/alert-firing.png)

### 6. Grafana dashboard
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo
```
Login `admin` → Dashboards → *Kubernetes / Compute Resources / Namespace (Pods)* → namespace `chhavi-demo`.

![Grafana CPU and memory dashboard](screenshots/grafana-dashboard.png)

---

## Task 2 — Observability

Monitoring tells you **when** something is wrong (known checks); observability lets you ask **why** using the data the system emits.

| Pillar | What it is | Example | Tools |
|---|---|---|---|
| Metrics | Numbers over time | CPU = 0.3 cores, 5xx rate, restarts | Prometheus, Grafana, CloudWatch |
| Logs | Timestamped event records | `GET / 200`, stack traces | `kubectl logs`, Loki, ELK/EFK |
| Traces | Path of one request across services | checkout → payment → DB, 800 ms in DB | Jaeger, Tempo, OpenTelemetry |

**Why it's needed:** microservices fail in unexpected ways; pods are short-lived, so problems can't be debugged by SSH-ing into a box; it lowers MTTR and helps catch issues before users do.

**Kubernetes observability:** kubelet/cAdvisor + kube-state-metrics → Prometheus (metrics), container stdout → `kubectl logs`/Loki (logs), OpenTelemetry → Jaeger/Tempo (traces), plus `kubectl get events` and probes for health.

---

## Task 3 — GitOps with Argo CD

**GitOps** = Git is the **single source of truth**; the desired state is written **declaratively** (YAML), and an agent in the cluster **continuously reconciles** live state to match Git.

```text
edit YAML → git push → Argo CD detects change → syncs cluster → live state = Git
                       ↑______ drift (kubectl edits) reverted by selfHeal ______|
```

### 1. Install Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl get pods -n argocd
```
![Argo CD pods running](screenshots/argocd-pods.png)

### 2. Create the Application
`homework/gitops-app/` must already be pushed to `main` on my fork.
```bash
kubectl apply -f session20-monitoring-observability-gitops/homework/argocd-application.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
![chhavi-gitops-app Synced and Healthy in Argo CD](screenshots/argocd-synced.png)

### 3. Change in Git → cluster follows
Change `replicas: 2` → `3` in `homework/gitops-app/deployment.yaml`, commit and push:
```bash
git add session20-monitoring-observability-gitops/homework/gitops-app/deployment.yaml
git commit -m "gitops: scale to 3" && git push
kubectl get deploy chhavi-gitops-app -n chhavi-gitops
```
![Argo CD synced the new commit, 3/3 replicas](screenshots/gitops-scale.png)

### 4. Self-heal — manual drift is reverted
```bash
kubectl scale deploy chhavi-gitops-app -n chhavi-gitops --replicas=5
kubectl get deploy chhavi-gitops-app -n chhavi-gitops -w
```
![Manual scale reverted back to 3 by Argo CD](screenshots/self-heal.png)
