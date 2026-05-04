#!/bin/bash

set -e

echo "--> Starting Minikube cluster..."
minikube start --cpus=2 --memory=4096

echo "--> Cleaning up any stale resources..."
# Delete the Crossplane release and deployment to ensure a fresh start
kubectl delete release.helm.crossplane.io/podinfo-release -n default 2>/dev/null || true
kubectl delete deployment/podinfo-release -n default 2>/dev/null || true
kubectl delete pods --all -n default --force --grace-period=0 2>/dev/null || true

echo "--> Adding Crossplane Helm repository..."
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update

echo "--> Installing Crossplane..."
helm install crossplane crossplane-stable/crossplane --namespace crossplane-system --create-namespace --wait

echo "--> Waiting for Crossplane pods to be ready..."
kubectl wait --for=condition=ready pod -l app=crossplane -n crossplane-system --timeout=120s
kubectl wait --for=condition=ready pod -l app=crossplane-rbac-manager -n crossplane-system --timeout=120s

echo "--> Applying Provider-Helm..."
kubectl apply -f provider.yaml

echo "--> Waiting for provider-helm to be installed and healthy..."
sleep 15
kubectl wait provider.pkg.crossplane.io/provider-helm --for=condition=Installed --timeout=180s
kubectl wait provider.pkg.crossplane.io/provider-helm --for=condition=Healthy --timeout=180s

echo "--> Applying ProviderConfig for Helm..."
kubectl apply -f provider-config.yaml

echo "--> Provisioning infrastructure (Podinfo via Helm Release)..."
kubectl apply -f release.yaml

echo "--> Waiting for the Release to become ready..."
sleep 10
kubectl wait release.helm.crossplane.io/podinfo-release --for=condition=Ready --timeout=180s || {
  echo "Release failed to become ready. Debug info:"
  kubectl describe release.helm.crossplane.io/podinfo-release
  exit 1
}

echo "--> Waiting for Podinfo deployment to be created..."
sleep 15
echo "--> Waiting for podinfo-release deployment to be available..."
kubectl wait --for=condition=available deployment/podinfo-release -n default --timeout=300s

echo "--> Verifying the pods and their creation time..."
kubectl get pods -n default -o wide
echo "--> SUCCESS: Crossplane successfully provisioned the resource."

echo "--> Cleaning up..."
minikube delete
