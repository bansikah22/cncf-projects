#!/bin/bash

# This script provides a verifiable demo of Istio's traffic splitting
# capabilities using a local minikube cluster.

set -e

DEMO_DIR="istio/demo"

# Cleanup function to be called on script exit and start
cleanup() {
  echo "--> Cleaning up..."
  # Stop the tunnel process if it's running
  pkill -f 'minikube tunnel' || true
  minikube delete
}
trap cleanup EXIT
cleanup

echo "--> 1. Starting minikube cluster..."
# Istio is resource-intensive, so we allocate more resources.
minikube start --memory=4096 --cpus=4

echo "--> 2. Installing Istio..."
# Download and install the latest version of istioctl
curl -L https://istio.io/downloadIstio | sh -
# Find the istio directory (e.g., istio-1.29.1) and add istioctl to the path
ISTIO_DIR=$(find . -maxdepth 1 -type d -name "istio-*" | head -n 1)
export PATH=$PATH:$(pwd)/$ISTIO_DIR/bin
istioctl install --set profile=demo -y

echo "--> 3. Enabling automatic sidecar injection..."
kubectl label namespace default istio-injection=enabled

echo "--> 4. Deploying the helloworld application (v1 & v2)..."
kubectl apply -f "$DEMO_DIR/helloworld-app.yaml"
kubectl wait --for=condition=available --timeout=120s deployment/helloworld-v1
kubectl wait --for=condition=available --timeout=120s deployment/helloworld-v2

echo "--> 5. Applying Istio Gateway and VirtualService for traffic splitting..."
kubectl apply -f "$DEMO_DIR/routing-rules.yaml"

echo "--> 6. Setting up access to the Istio Ingress Gateway via NodePort..."
# Change the service type from LoadBalancer to NodePort
kubectl patch svc istio-ingressgateway -n istio-system -p '{"spec": {"type": "NodePort"}}'

# Get the IP of the minikube node
NODE_IP=$(minikube ip)

# Get the assigned NodePort for HTTP traffic
NODE_PORT=$(kubectl get svc istio-ingressgateway -n istio-system -o 'jsonpath={.spec.ports[?(@.name=="http2")].nodePort}')

INGRESS_URL="http://$NODE_IP:$NODE_PORT"
echo "Istio Ingress Gateway is available at: $INGRESS_URL"

echo "--> Waiting for the Ingress Gateway to be ready..."
RETRY_COUNT=0
MAX_RETRIES=12
until curl -s --head --fail "$INGRESS_URL" > /dev/null; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "--> FAILURE: Ingress Gateway did not become ready in time."
    exit 1
  fi
  echo "Gateway not ready yet, waiting 10s... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 10
done
echo "Gateway is ready!"

echo "--> 7. Verifying the 90/10 traffic split..."
echo "Sending 100 requests to the service..."
V1_COUNT=0
V2_COUNT=0
for i in {1..100}; do
  RESPONSE=$(curl -s "$INGRESS_URL")
  if echo "$RESPONSE" | grep -q "v1"; then
    V1_COUNT=$((V1_COUNT+1))
  elif echo "$RESPONSE" | grep -q "v2"; then
    V2_COUNT=$((V2_COUNT+1))
  fi
  # Add a small visual progress indicator
  echo -n "."
done
echo "" # Newline after the progress indicator

echo "--> Verification complete."
echo "    Responses from v1: $V1_COUNT"
echo "    Responses from v2: $V2_COUNT"

# Check if the results are within a reasonable range (e.g., 80-100 for v1, 1-20 for v2)
if [ "$V1_COUNT" -gt 80 ] && [ "$V1_COUNT" -le 100 ] && [ "$V2_COUNT" -gt 0 ] && [ "$V2_COUNT" -lt 20 ]; then
  echo "--> SUCCESS: Traffic split is approximately 90/10."
else
  echo "--> FAILURE: Traffic split is not working as expected."
  exit 1
fi

echo "--> Istio demo completed successfully!"
# Cleanup will be handled automatically by the trap
