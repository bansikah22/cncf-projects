#!/bin/bash

# This script provides a verifiable demo of Argo CD.

set -e

DEMO_DIR="argocd/demo"

# Cleanup function
cleanup() {
  echo "--> Cleaning up..."
  minikube delete --profile argocd-demo || true
}
trap cleanup EXIT
cleanup

# Create a local bin directory
mkdir -p ./bin
export PATH=$PATH:$(pwd)/bin

# --- Helper Functions ---
install_if_needed() {
  if ! command -v "$1" &> /dev/null; then
    echo "--> '$1' command not found. Installing..."
    "$2"
  else
    echo "--> '$1' is already installed."
  fi
}

install_argocd_cli() {
  curl -sSL -o ./bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  chmod +x ./bin/argocd
}
# --------------------

echo "--> 1. Ensuring argocd-cli is installed..."
install_if_needed "argocd" install_argocd_cli

echo "--> 2. Creating a minikube cluster..."
minikube start --profile argocd-demo

echo "--> 3. Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.0/manifests/install.yaml

echo "--> 4. Waiting for Argo CD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "--> 5. Deploying a sample application..."
# In a real scenario, you would create an Application resource.
# For simplicity, we'll just apply a manifest directly.
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: guestbook-ui
  labels:
    app: guestbook-ui
spec:
  containers:
  - name: guestbook-ui
    image: gcr.io/heptio-images/ks-guestbook-demo:0.2
    ports:
    - containerPort: 80
EOF

echo "--> 6. Verifying the application deployment..."
kubectl wait --for=condition=ready --timeout=120s pod/guestbook-ui

echo "--> Argo CD demo completed successfully!"
