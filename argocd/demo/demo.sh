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
echo "--> Argo CD server is available. Waiting for CRDs to be established..."
kubectl wait --for condition=established --timeout=60s crd/applications.argoproj.io
sleep 15

echo "--> 5. Deploying a sample application via Argo CD..."
kubectl apply -f "$DEMO_DIR/application.yaml"

echo "--> 6. Verifying the application deployment..."
# Stream the sync status to see the progress
argocd app get guestbook --show-operation --show-sync-status &
# Wait for Argo CD to report the application is synced and healthy
kubectl wait --for=condition=healthy --timeout=600s application/guestbook -n argocd
kubectl wait --for=condition=synced --timeout=600s application/guestbook -n argocd
echo "--> SUCCESS: Application is healthy and synced."

echo "--> Argo CD demo completed successfully!"
