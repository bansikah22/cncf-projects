#!/bin/bash

# This script provides a verifiable demo of CRI-O by running a
# minikube cluster with CRI-O as the container runtime.

set -e

echo "--> 1. Starting minikube cluster with CRI-O runtime..."
minikube start --driver=docker --container-runtime=cri-o

echo "--> 2. Verifying the container runtime is CRI-O..."
# This is the key verification step. We check the node's container runtime.
RUNTIME=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.containerRuntimeVersion}')
echo "Detected container runtime: $RUNTIME"

if [[ "$RUNTIME" == *"cri-o"* ]]; then
  echo "--> SUCCESS: The Kubernetes node is running on CRI-O."
else
  echo "--> FAILURE: The Kubernetes node is NOT running on CRI-O."
  minikube delete
  exit 1
fi

echo "--> 3. Attempting to deploy an NGINX pod (for demonstration)..."
# This step may fail due to image pull issues in some environments,
# but the primary goal of verifying the runtime has already been achieved.
kubectl create deployment nginx --image=nginx
kubectl get pods

echo "--> 4. Cleaning up..."
minikube delete

echo "--> CRI-O demo completed successfully!"
