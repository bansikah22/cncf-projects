#!/bin/bash

# This script provides a verifiable demo of Cilium's network policy
# capabilities using a local kind (Kubernetes in Docker) cluster.

set -e

DEMO_DIR="cilium/demo"

# Cleanup function
cleanup() {
  echo "--> Cleaning up..."
  kind delete cluster --name cilium-demo || true
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

install_kind() {
  curl -Lo ./bin/kind "https://kind.sigs.k8s.io/dl/v0.20.0/kind-$(uname)-amd64"
  chmod +x ./bin/kind
}

install_cilium_cli() {
  curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-amd64.tar.gz.sha256sum
  tar xzvfC cilium-linux-amd64.tar.gz ./bin
  chmod +x ./bin/cilium
  rm cilium-linux-amd64.tar.gz{,.sha256sum}
}
# --------------------

echo "--> 1. Ensuring kind and cilium-cli are installed..."
install_if_needed "kind" install_kind
install_if_needed "cilium" install_cilium_cli

echo "--> 2. Creating a kind cluster..."
kind create cluster --name cilium-demo

echo "--> 3. Installing Cilium..."
cilium install --wait

echo "--> 4. Pre-loading application image into the cluster..."
# Pull the image locally
docker pull bansikah/kubesrv:latest
# Load the image into the kind cluster nodes
kind load docker-image bansikah/kubesrv:latest --name cilium-demo

echo "--> 5. Deploying test applications (leia and luke)..."
kubectl apply -f "$DEMO_DIR/apps.yaml"
kubectl wait --for=condition=available --timeout=120s deployment/leia
kubectl wait --for=condition=available --timeout=120s deployment/luke
sleep 5 # Give pods time to fully initialize

echo "--> 6. Verifying initial connectivity (luke to leia)..."
# Exec into the luke pod and use wget to try and reach the leia service
if kubectl exec deploy/luke -- wget -qO- --timeout=5 http://leia; then
  echo "--> SUCCESS: leia is reachable from luke before policy is applied."
else
  echo "--> FAILURE: leia is NOT reachable from luke before policy is applied."
  exit 1
fi

echo "--> 7. Applying network policy to block traffic..."
kubectl apply -f "$DEMO_DIR/network-policy.yaml"
echo "Policy applied. Waiting 10s for it to take effect..."
sleep 10

echo "--> 8. Verifying blocked connectivity (luke to leia)..."
# This command is expected to fail (return a non-zero exit code)
if ! kubectl exec deploy/luke -- wget -qO- --timeout=5 http://leia; then
  echo "--> SUCCESS: leia is NOT reachable from luke after policy is applied. This is the expected behavior."
else
  echo "--> FAILURE: leia is still reachable. The policy was not effective."
  exit 1
fi

echo "--> 7. Applying network policy to block traffic..."
kubectl apply -f "$DEMO_DIR/network-policy.yaml"
echo "Policy applied. Waiting 10s for it to take effect..."
sleep 10

echo "--> 8. Verifying blocked connectivity (luke to leia)..."
# This command is expected to fail (return a non-zero exit code)
if ! kubectl exec deploy/luke -- wget -qO- --timeout=5 http://leia; then
  echo "--> SUCCESS: leia is NOT reachable from luke after policy is applied. This is the expected behavior."
else
  echo "--> FAILURE: leia is still reachable. The policy was not effective."
  exit 1
fi

echo "--> Cilium demo completed successfully!"
# Cleanup will be handled automatically by the trap
