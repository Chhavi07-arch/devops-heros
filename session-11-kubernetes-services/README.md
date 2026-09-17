# Session 11 — Kubernetes Networking & Services (Homework)

**Name:** Chhavi Ahlawat
**Enrollment Number:** 24BCS10201
**Email:** chhavi.24bcs10201@sst.scaler.com

---

## Homework Tasks

| Task | Description | Status |
|---|---|---|
| 1 | ClusterIP — internal-only service | ✅ |
| 2 | NodePort — external access via node IP | ✅ |
| 3 | LoadBalancer — cloud-provisioned external LB | ✅ |
| 4 | ExternalName — DNS alias to an external host | ✅ |
| 5 | Headless Service — direct per-pod DNS | ✅ |
| 6 | FQDN / CoreDNS resolution test | ✅ |

---

## Folder Guide

| Folder | Service Type |
|---|---|
| [`01-clusterip/`](01-clusterip/README.md) | ClusterIP |
| [`02-nodeport/`](02-nodeport/README.md) | NodePort |
| [`03-loadbalancer/`](03-loadbalancer/README.md) | LoadBalancer |
| [`04-externalname/`](04-externalname/README.md) | ExternalName |
| [`05-headless/`](05-headless/README.md) | Headless (`clusterIP: None`) |
| [`dns-test/`](dns-test) | Pod used to test in-cluster DNS |
| [`troubleshooting/`](troubleshooting) | Empty-endpoints (selector mismatch) |

Concept deep-dives: [`service.md`](service.md) (all 5 service types) and [`fqdn.md`](fqdn.md) (CoreDNS/FQDN).

---

## 1. ClusterIP
```bash
kubectl apply -f 01-clusterip/app-deployment.yaml
kubectl apply -f 01-clusterip/service.yaml
kubectl apply -f 01-clusterip/client-pod.yaml
kubectl exec -it curl-client -- curl web-service-clusterip:8080
```
📸 `screenshots/clusterip.png`

## 2. NodePort
```bash
kubectl apply -f 02-nodeport/app-deployment.yaml
kubectl apply -f 02-nodeport/service.yaml
kubectl get svc web-service-nodeport
curl http://$(minikube ip):30080
```
📸 `screenshots/nodeport.png`

## 3. LoadBalancer
```bash
kubectl apply -f 03-loadbalancer/app-deployment.yaml
kubectl apply -f 03-loadbalancer/service.yaml
kubectl get svc web-service-loadbalancer
minikube tunnel        # run in a separate terminal to assign an EXTERNAL-IP
```
📸 `screenshots/loadbalancer.png`

## 4. ExternalName
```bash
kubectl apply -f 04-externalname/service.yaml
kubectl apply -f 04-externalname/client-pod.yaml
kubectl exec -it dns-test-client -- nslookup external-database-service
```
📸 `screenshots/externalname.png`

## 5. Headless Service
```bash
kubectl apply -f 05-headless/app-statefulset.yaml
kubectl apply -f 05-headless/service.yaml
kubectl apply -f 05-headless/client-pod.yaml
kubectl exec -it headless-dns-client -- nslookup web-service-headless
```
📸 `screenshots/headless.png` — DNS returning multiple pod IPs instead of one VIP

## 6. FQDN / DNS Test
```bash
kubectl apply -f dns-test/curl-test-pod.yaml
kubectl exec -it curl-test-pod -- cat /etc/resolv.conf
kubectl exec -it curl-test-pod -- nslookup web-service-clusterip.default.svc.cluster.local
```
📸 `screenshots/fqdn-dns-test.png`

## 7. Troubleshooting
```bash
kubectl apply -f troubleshooting/empty-endpoints.yaml
kubectl get endpoints broken-backend-service     # empty — selector matches no pod
kubectl describe svc broken-backend-service
```
📸 `screenshots/troubleshooting.png`

---

## Cleanup
```bash
kubectl delete -f 01-clusterip/service.yaml -f 01-clusterip/client-pod.yaml -f 01-clusterip/app-deployment.yaml
kubectl delete -f 02-nodeport/service.yaml -f 02-nodeport/app-deployment.yaml
kubectl delete -f 03-loadbalancer/service.yaml -f 03-loadbalancer/app-deployment.yaml
kubectl delete -f 04-externalname/service.yaml -f 04-externalname/client-pod.yaml
kubectl delete -f 05-headless/service.yaml -f 05-headless/client-pod.yaml -f 05-headless/app-statefulset.yaml
kubectl delete -f dns-test/curl-test-pod.yaml
kubectl delete -f troubleshooting/empty-endpoints.yaml
```

---

## Resources
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/
