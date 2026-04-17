#!/bin/bash

# This script provides a fully self-contained, end-to-end demonstration of SPIRE
# providing workload identity to a client and server for secure mTLS communication.

set -e

CLUSTER_NAME="spire-demo"
SERVER_IMAGE="spire-server-app:latest"
CLIENT_IMAGE="spire-client-app:latest"

# --- Helper Functions ---
info() {
    echo
    echo "--- $1 ---"
}

# --- Cleanup ---
if [[ "$1" == "cleanup" ]]; then
    info "Cleaning up all resources"
    set +e # Don't exit on error during cleanup
    kind delete cluster --name $CLUSTER_NAME
    docker rmi $SERVER_IMAGE $CLIENT_IMAGE > /dev/null 2>&1
    info "Cleanup complete."
    exit 0
fi

# --- Demo Steps ---

# 1. Start Kind Cluster
if ! kind get clusters | grep -q $CLUSTER_NAME; then
    info "Creating kind cluster: $CLUSTER_NAME"
    kind create cluster --name $CLUSTER_NAME
else
    info "Kind cluster '$CLUSTER_NAME' already exists"
fi
info "Kubernetes cluster is ready"

# 2. Build and Load Custom Images
info "Building custom server and client images"
docker build -t $SERVER_IMAGE -f spire/demo/server/Dockerfile spire/demo
docker build -t $CLIENT_IMAGE -f spire/demo/client/Dockerfile spire/demo
info "Loading images into the kind cluster"
kind load docker-image $SERVER_IMAGE --name $CLUSTER_NAME
kind load docker-image $CLIENT_IMAGE --name $CLUSTER_NAME
info "Custom images are loaded"

# 3. Install SPIRE
info "Installing SPIRE"
kubectl apply -k github.com/spiffe/spire-tutorials/k8s/quickstart
info "Waiting for SPIRE components to be ready..."
kubectl wait --for=condition=ready pod -l app=spire-server -n spire --timeout=300s
kubectl wait --for=condition=ready pod -l app=spire-agent -n spire --timeout=300s
info "SPIRE is installed and running"

# 4. Deploy the Server Application
info "Deploying the server application"
kubectl apply -f spire/demo/k8s/server.yaml
kubectl wait --for=condition=ready pod -l app=server --timeout=300s
SERVER_POD=$(kubectl get pods -l app=server -o jsonpath='{.items[0].metadata.name}')
info "Server is running (pod: $SERVER_POD)"

# 5. Register the Workloads with SPIRE
info "Registering the workloads with SPIRE"
SPIRE_SERVER_POD=$(kubectl get pods -n spire -l app=spire-server -o jsonpath='{.items[0].metadata.name}')

# Register the node
kubectl exec -n spire $SPIRE_SERVER_POD -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s_psat:cluster:demo-cluster \
    -selector k8s_psat:agent_ns:spire \
    -selector k8s_psat:agent_sa:spire-agent \
    -node

# Register the server
kubectl exec -n spire $SPIRE_SERVER_POD -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/server \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:pod-label:app:server

# Register the client
kubectl exec -n spire $SPIRE_SERVER_POD -- \
    /opt/spire/bin/spire-server entry create \
    -spiffeID spiffe://example.org/client \
    -parentID spiffe://example.org/ns/spire/sa/spire-agent \
    -selector k8s:ns:default \
    -selector k8s:pod-label:app:client

info "Workload registration complete"

# 6. Run the Client and Verify mTLS
info "--- Starting the mTLS test ---"
info "Deploying the client pod..."
kubectl apply -f spire/demo/k8s/client.yaml
info "Waiting for the client to complete..."
kubectl wait --for=condition=complete job/client --timeout=120s
info "Client has completed. Checking logs..."
CLIENT_POD=$(kubectl get pods -l app=client --field-selector=status.phase=Succeeded -o jsonpath='{.items[0].metadata.name}')
kubectl logs $CLIENT_POD

# 7. Verify and Finalize
info "--- Test Complete ---"
echo "The server logs should show a request from 'spiffe://example.org/client'."
echo "The client logs should show it received a greeting from the server."
kubectl logs $CLIENT_POD | grep "Greeting: Hello" && info "SUCCESS: Client successfully established mTLS connection and received greeting from server." || (info "ERROR: Client did not receive greeting." && exit 1)

info "To clean up all resources, run: ./spire/demo/demo.sh cleanup"

exit 0
