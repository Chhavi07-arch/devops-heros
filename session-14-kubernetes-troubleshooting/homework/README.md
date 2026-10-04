# Session 14 — Kubernetes Troubleshooting (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | kubectl get / describe / logs / exec / events / explain / top / -o wide | ✅ |
| 2 | Debug CrashLoopBackOff, ImagePullBackOff/ErrImagePull, Pending, ContainerCreating, config, Service, DNS and networking issues | ✅ |
| 3 | Mini project: debug the broken pod and the Service selector | ✅ |

All commands are run from `session-14-kubernetes-troubleshooting/` on minikube:
```bash
minikube start
minikube addons enable metrics-server     # needed for kubectl top
```

---

## 1. Core kubectl Commands

```bash
kubectl apply -f 01-kubectl-get/pod.yaml -f 03-kubectl-logs/pod.yaml
kubectl get pods -o wide
kubectl describe pod get-demo | tail -15
kubectl logs logs-demo --tail=5
```
![get -o wide, describe events and logs output](../screenshots/kubectl-basics.png)

```bash
kubectl exec get-demo -- curl -s localhost | head -4
kubectl get events --sort-by=.lastTimestamp | tail -10
kubectl explain pod.spec.containers.livenessProbe | head -15
kubectl top pods
```
![exec into the container, events, explain and top](../screenshots/kubectl-exec-events.png)

---

## 2. Troubleshooting Scenarios

Every scenario follows the same steps: **get → describe (Events) → logs → fix → verify**.

### CrashLoopBackOff (`06-crashloopbackoff/`)
**Problem:** `crash-demo` keeps restarting and ends up in `CrashLoopBackOff`.  
**Root cause:** the container command runs `exit 1`, so the process dies as soon as it starts.  
**Fix:** use a command that keeps the process running (`sleep 3600`).
```bash
kubectl apply -f 06-crashloopbackoff/broken-pod.yaml
kubectl get pod crash-demo                 # wait ~20s for RESTARTS > 0
kubectl logs crash-demo --previous
kubectl describe pod crash-demo | grep -A3 'Last State'
kubectl delete pod crash-demo && kubectl apply -f 06-crashloopbackoff/fixed-pod.yaml
kubectl get pod crash-demo
```
![crash-demo going from CrashLoopBackOff to Running](../screenshots/crashloopbackoff.png)

### ImagePullBackOff / ErrImagePull (`07-imagepullbackoff/`)
**Problem:** `image-demo` shows `ErrImagePull` first, then `ImagePullBackOff`.  
**Root cause:** the tag `nginx:this-image-does-not-exist` isn't in the registry.  
**Fix:** use a real tag, `nginx:1.27`.
```bash
kubectl apply -f 07-imagepullbackoff/broken-pod.yaml
kubectl get pod image-demo -w            # ErrImagePull -> ImagePullBackOff, Ctrl+C
kubectl describe pod image-demo | grep -A8 Events
kubectl delete pod image-demo && kubectl apply -f 07-imagepullbackoff/fixed-pod.yaml
kubectl get pod image-demo
```
![ErrImagePull/ImagePullBackOff, the "not found" event, then Running after the fix](../screenshots/imagepullbackoff.png)

### Pending (`08-pending-pods/`)
**Problem:** `pending-demo` stays `Pending` and never gets scheduled.  
**Root cause:** `nodeSelector: kubernetes.io/hostname: node-that-does-not-exist` doesn't match any node (`FailedScheduling`).  
**Fix:** remove the nodeSelector.
```bash
kubectl apply -f 08-pending-pods/broken-pod.yaml
kubectl get pod pending-demo
kubectl describe pod pending-demo | grep -A5 Events
kubectl get nodes --show-labels | grep hostname
kubectl delete pod pending-demo && kubectl apply -f 08-pending-pods/fixed-pod.yaml
kubectl get pod pending-demo -o wide
```
![FailedScheduling because of the node selector, then the Pod scheduled on minikube](../screenshots/pending.png)

### ContainerCreating (`10-containercreating/`, added)
**Problem:** `containercreating-demo` is stuck in `ContainerCreating`.  
**Root cause:** it mounts ConfigMap `cc-demo-config`, which doesn't exist (`FailedMount` event).  
**Fix:** create the ConfigMap. The kubelet retries the mount and the Pod starts.
```bash
kubectl apply -f 10-containercreating/broken-pod.yaml
kubectl get pod containercreating-demo
kubectl describe pod containercreating-demo | grep -A5 Events
kubectl apply -f 10-containercreating/configmap.yaml
kubectl get pod containercreating-demo -w     # Running, Ctrl+C
```
![FailedMount: configmap not found, then Running once the ConfigMap exists](../screenshots/containercreating.png)

### Config issue (`11-config-issues/`, added)
**Problem:** `config-demo` shows `CreateContainerConfigError`.  
**Root cause:** the env var refers to key `DATABASE_URL`, but ConfigMap `config-demo-cm` only has `DB_URL`.  
**Fix:** point `configMapKeyRef.key` at `DB_URL`.
```bash
kubectl apply -f 11-config-issues/configmap.yaml -f 11-config-issues/broken-pod.yaml
kubectl get pod config-demo
kubectl describe pod config-demo | grep -A5 Events
kubectl get configmap config-demo-cm -o yaml
kubectl delete pod config-demo && kubectl apply -f 11-config-issues/fixed-pod.yaml
kubectl logs config-demo
```
![CreateContainerConfigError for the missing key, fixed and printing DATABASE_URL](../screenshots/config-issue.png)

### Service connectivity (`09-service-dns-troubleshooting/`)
**Problem:** `web-service` exists, but it has no endpoints, so it can't reach the pods.  
**Root cause:** the Service selector is `app: web-ahsgdf`, but the pods are labelled `app: web`.  
**Fix:** change the selector to `app: web`.
```bash
kubectl apply -f 09-service-dns-troubleshooting/deployment.yaml -f 09-service-dns-troubleshooting/service.yaml
kubectl get endpoints web-service                       # <none>
kubectl get pods -l app=web --show-labels
kubectl describe service web-service | grep Selector
kubectl patch service web-service -p '{"spec":{"selector":{"app":"web"}}}'
kubectl get endpoints web-service                       # 2 pod IPs
```
![Empty endpoints because of the selector/label mismatch, filled in after the patch](../screenshots/service-endpoints.png)

### DNS + pod networking
**Problem:** a lookup for `web-svc` fails with `NXDOMAIN`.  
**Root cause:** wrong Service name. DNS names follow `<service>.<namespace>.svc.cluster.local`.  
**Fix:** use `web-service` (or its full name). Then check the pod network directly by reaching a pod IP.
```bash
kubectl apply -f 09-service-dns-troubleshooting/dns-test-pod.yaml
kubectl wait --for=condition=Ready pod/dns-test --timeout=120s
kubectl exec dns-test -- nslookup web-svc                                   # fails
kubectl exec dns-test -- nslookup web-service.default.svc.cluster.local     # resolves
kubectl exec dns-test -- cat /etc/resolv.conf
kubectl get pods -n kube-system -l k8s-app=kube-dns
POD_IP=$(kubectl get pods -l app=web -o jsonpath='{.items[0].status.podIP}')
kubectl run net-test --rm -it --image=busybox:1.36 --restart=Never -- \
  sh -c "wget -qO- http://web-service | head -4; wget -qO- http://$POD_IP | head -4"
```
![NXDOMAIN vs a resolved FQDN, CoreDNS running, and both the Service and the pod IP reachable](../screenshots/dns-networking.png)

---

## 3. Mini Project (`mini-project/`)

### Broken pod
```bash
cd mini-project
kubectl apply -f deployment.yaml -f service.yaml -f broken-pod.yaml
kubectl get pods -o wide
kubectl describe pod project-broken-pod | grep -A8 Events
kubectl set image pod/project-broken-pod app=nginx:1.27
kubectl get pod project-broken-pod
```
![project-broken-pod in ImagePullBackOff, fixed with set image](../screenshots/mini-project-broken-pod.png)

| Q | Answer |
|---|---|
| 1. Pod status? | `ErrImagePull`, then `ImagePullBackOff` |
| 2. Actual error? | `manifest for nginx:this-tag-does-not-exist not found` |
| 3. Command that found it? | `kubectl describe pod project-broken-pod` (Events) |
| 4. What's wrong with the image? | The tag doesn't exist on Docker Hub |
| 5. Fix? | Use a valid tag (`nginx:1.27`) in the YAML, or `kubectl set image` |

### Service selector
```bash
kubectl patch service troubleshooting-service -p '{"spec":{"selector":{"app":"wrong-app"}}}'
kubectl get endpoints troubleshooting-service           # <none>
kubectl get pods --show-labels | grep troubleshooting
kubectl apply -f service.yaml                           # restore app: troubleshooting-app
kubectl get endpoints troubleshooting-service
POD=$(kubectl get pods -l app=troubleshooting-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- curl -s localhost | head -4
```
![Endpoints empty with the wrong selector, restored afterwards, and nginx answering inside the pod](../screenshots/mini-project-service.png)

### Troubleshooting table
| Problem | What I Saw | Command I Used | Root Cause | Fix |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | `ImagePullBackOff` | `kubectl describe pod` | Image tag doesn't exist | Valid tag `nginx:1.27` |
| **Service Problem** | Endpoints `<none>` | `kubectl get endpoints`, `--show-labels` | Selector `wrong-app` ≠ label `troubleshooting-app` | Fix the selector |
| **Image Problem** | `ErrImagePull` | `kubectl describe pod` (Events) | Registry has no such manifest | Correct the image reference |

### Questions
1. **get:** a quick status overview of resources (READY, STATUS, RESTARTS).
2. **get vs describe:** `get` is a one-line summary. `describe` gives the full detail plus Events.
3. **logs:** to read the app's stdout/stderr (`--previous` shows the output of a crashed container).
4. **exec:** to run commands inside a running container, e.g. curl, env or checking files.
5. **CrashLoopBackOff:** the container keeps exiting and Kubernetes waits longer before each restart.
6. **ImagePullBackOff:** the image can't be pulled (wrong name or tag, or no auth), so Kubernetes waits longer before each retry.
7. **Pending:** the scheduler can't place the Pod (not enough CPU/memory, no node matches the selector or affinity, taints, PVC not bound).
8. **No endpoints:** the selector matches no pods, or the matching pods aren't Ready.
9. **Selector ↔ labels:** a Service sends traffic to the pods whose labels match its selector.
10. **Kubernetes DNS:** CoreDNS resolves `<svc>.<ns>.svc.cluster.local` to the Service's ClusterIP.

---

## Cleanup
```bash
# from mini-project/
kubectl delete -f deployment.yaml -f service.yaml -f broken-pod.yaml
cd ..
kubectl delete pod get-demo logs-demo crash-demo image-demo pending-demo containercreating-demo config-demo dns-test --ignore-not-found
kubectl delete configmap cc-demo-config config-demo-cm
kubectl delete -f 09-service-dns-troubleshooting/deployment.yaml -f 09-service-dns-troubleshooting/service.yaml
```

---

## Resources
- https://kubernetes.io/docs/tasks/debug/debug-application/
- https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/
- https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
