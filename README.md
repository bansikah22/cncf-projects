# 🚀 CNCF Projects to Learn with Demos (Top 31)

This document provides a curated list of **CNCF projects** with:
- 🌐 Official documentation links  
- 🧪 Suggested hands-on demos  
- 💼 Real-world relevance  

---

# 🧠 1. Core Kubernetes Ecosystem (MUST KNOW)

## 1. Kubernetes
- 🔗 https://kubernetes.io
- 🧪 Demo: Deploy a simple app (NGINX) with a Service and Ingress

## 2. etcd
- 🔗 https://etcd.io
- 🧪 Demo: Store and retrieve key-value data using `etcdctl`

## 3. CoreDNS
- 🔗 https://coredns.io
- 🧪 Demo: Customize DNS resolution inside a Kubernetes cluster

## 4. containerd
- 🔗 https://containerd.io
- 🧪 Demo: Run a container using `ctr` CLI

## 5. CRI-O
- 🔗 https://cri-o.io
- 🧪 Demo: Understand CRI by integrating CRI-O with Kubernetes

---

# 📦 2. Packaging, Deployment & GitOps

## 6. Helm
- 🔗 https://helm.sh
- 🧪 Demo: Package and deploy a Helm chart

## 7. Kustomize
- 🔗 https://kustomize.io
- 🧪 Demo: Manage multiple environments (dev/prod)

## 8. Argo CD
- 🔗 https://argo-cd.readthedocs.io
- 🧪 Demo: GitOps deployment from GitHub repo

## 9. Argo Workflows
- 🔗 https://argoproj.github.io/workflows/
- 🧪 Demo: Run a simple CI pipeline in Kubernetes

## 10. Flux
- 🔗 https://fluxcd.io
- 🧪 Demo: Sync a Git repo to Kubernetes cluster

---

# 📊 3. Observability

## 11. Prometheus
- 🔗 https://prometheus.io
- 🧪 Demo: Monitor Kubernetes metrics

## 12. Grafana
- 🔗 https://grafana.com
- 🧪 Demo: Build dashboards for Prometheus metrics

## 13. Jaeger
- 🔗 https://www.jaegertracing.io
- 🧪 Demo: Trace requests across microservices

## 14. OpenTelemetry
- 🔗 https://opentelemetry.io
- 🧪 Demo: Instrument an app for tracing + metrics

## 15. Fluentd
- 🔗 https://www.fluentd.org
- 🧪 Demo: Collect and forward logs

---

# 🌐 4. Networking & Service Mesh

## 16. Envoy
- 🔗 https://www.envoyproxy.io
- 🧪 Demo: Run Envoy as a reverse proxy

## 17. Istio
- 🔗 https://istio.io
- 🧪 Demo: Traffic routing between services

## 18. Linkerd
- 🔗 https://linkerd.io
- 🧪 Demo: Lightweight service mesh setup

## 19. Cilium
- 🔗 https://cilium.io
- 🧪 Demo: Network policies using eBPF

---

# 🔐 5. Security & Policy (DevSecOps)

## 20. Open Policy Agent (OPA)
- 🔗 https://www.openpolicyagent.org
- 🧪 Demo: Write policy rules for Kubernetes

## 21. Kyverno
- 🔗 https://kyverno.io
- 🧪 Demo: Enforce policies on resources

## 22. Falco
- 🔗 https://falco.org
- 🧪 Demo: Detect runtime security threats

## 23. cert-manager
- 🔗 https://cert-manager.io
- 🧪 Demo: Auto-generate TLS certificates

## 24. SPIFFE
- 🔗 https://spiffe.io
- 🧪 Demo: Identity-based authentication

## 25. SPIRE
- 🔗 https://spiffe.io/spire/
- 🧪 Demo: Workload identity management

---

# 📡 6. Scaling, Serverless & Event-Driven

## 26. KEDA
- 🔗 https://keda.sh
- 🧪 Demo: Auto-scale based on queue events

## 27. Knative
- 🔗 https://knative.dev
- 🧪 Demo: Deploy serverless app

## 28. Dapr
- 🔗 https://dapr.io
- 🧪 Demo: Build microservices with sidecars

---

# 🗄️ 7. Storage, Registry & Virtualization

## 29. Rook
- 🔗 https://rook.io
- 🧪 Demo: Deploy Ceph storage in Kubernetes

## 30. Harbor
- 🔗 https://goharbor.io
- 🧪 Demo: Run a private container registry

## 31. KubeVirt
- 🔗 https://kubevirt.io
- 🧪 Demo: Run a virtual machine inside Kubernetes

---

# 🧭 Suggested Learning Path

## 🥇 Phase 1 (Start Here)
- Kubernetes
- Helm
- Argo CD
- Prometheus + Grafana

## 🥈 Phase 2
- Flux / Argo Workflows
- OpenTelemetry
- Cilium
- cert-manager

## 🥉 Phase 3 (Advanced)
- Istio / Linkerd
- OPA / Kyverno
- SPIFFE / SPIRE
- KEDA / Knative
- KubeVirt (for hybrid environments)

---

# 🎯 How to Use This List

For each project:
1. Read the official docs  
2. Run the demo  
3. Build a small project  
4. Push to GitHub  

---

# 🔥 Pro Tip

Combine tools into real-world setups:

- Kubernetes + Helm + ArgoCD (GitOps)
- Prometheus + Grafana + OpenTelemetry (Observability)
- Istio + OPA + cert-manager (Security)
- KubeVirt + Kubernetes (Hybrid VM + Container workloads)

---

# 📌 Goal

Become confident in:
- Cloud-native architecture  
- Kubernetes ecosystem  
- Real DevOps workflows  
