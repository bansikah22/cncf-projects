#!/bin/bash

# This script provides a verifiable, realistic demo of Argo CD's GitOps capabilities.
# It demonstrates using Kustomize with a base/overlay structure and shows how a
# change in the Git-managed configuration is automatically applied to the cluster.

set -e

DEMO_DIR="argocd/demo"
KUSTOMIZE_PATCH_FILE="$DEMO_DIR/guestbook-gitops/overlays/staging/patch.yaml"

# Cleanup function
cleanup() {
  echo "--> Cleaning up..."
  # Kill the port-forwarding process if it's running
  if [ -n "$ARGOCD_PORT_FORWARD_PID" ]; then
    kill "$ARGOCD_PORT_FORWARD_PID"
  fi
  # Restore the original patch file to avoid committing the change
  git checkout -- "$KUSTOMIZE_PATCH_FILE"
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

echo "--> 5. Authenticating with Argo CD..."
# Get the auto-generated admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# Port-forward the Argo CD server to localhost
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
ARGOCD_PORT_FORWARD_PID=$!
# Wait a moment for the port-forward to be ready
sleep 5
# Login using the password
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure
# Kill the port-forwarding process now that we are logged in
kill "$ARGOCD_PORT_FORWARD_PID"

echo "--> 6. Deploying guestbook app using local Kustomize config (2 replicas)..."
kubectl apply -f "$DEMO_DIR/application.yaml"

echo "--> 7. Verifying the application syncs and is healthy..."
# This command is a bit more robust for waiting on sync status
argocd app wait guestbook --sync --health --timeout 300
echo "--> SUCCESS: Application has synced successfully."

echo "--> 8. Verifying the deployment has the correct initial replica count (2)..."
REPLICAS=$(kubectl get deployment -n guestbook guestbook-ui -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -ne 2 ]; then
  echo "--> FAILURE: Expected 2 replicas but found $REPLICAS."
  exit 1
fi
echo "--> SUCCESS: Deployment has 2 replicas, as defined in the staging overlay."

echo "--> 9. Simulating a Git change: updating replica count to 3..."
sed -i 's/replicas: 2/replicas: 3/' "$KUSTOMIZE_PATCH_FILE"
echo "--> Change applied to $KUSTOMIZE_PATCH_FILE. Argo CD will now detect and sync this change."

# We need to tell Argo CD to check for changes. In a real setup, this is done via a webhook or periodic polling.
# For the demo, we'll trigger a refresh manually.
echo "--> Forcing Argo CD to refresh the application source..."
argocd app refresh guestbook
# Now we wait for it to re-sync
echo "--> Waiting for the application to re-sync with the new configuration..."
argocd app wait guestbook --sync --health --timeout 300
echo "--> SUCCESS: Application has re-synced successfully."

echo "--> 10. Verifying the deployment has been scaled to 3 replicas..."
REPLICAS=$(kubectl get deployment -n guestbook guestbook-ui -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -ne 3 ]; then
  echo "--> FAILURE: Expected 3 replicas after sync but found $REPLICAS."
  exit 1
fi
echo "--> SUCCESS: Deployment has been automatically scaled to 3 replicas!"

echo "--> Argo CD GitOps demo completed successfully!"
