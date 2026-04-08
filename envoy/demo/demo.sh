#!/bin/bash

# This script runs a verifiable Envoy demo using Docker.

set -e

DEMO_DIR="envoy/demo"
NETWORK_NAME="envoy-net"

# Cleanup function
cleanup() {
  echo "--> Cleaning up any previous runs..."
  docker stop envoy-proxy backend-service || true
  docker rm envoy-proxy backend-service || true
  docker network rm $NETWORK_NAME || true
}
trap cleanup EXIT
cleanup

echo "--> 1. Setting up Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || true

echo "--> 2. Building the backend service image..."
docker build -t backend-service-image "$DEMO_DIR"

echo "--> 3. Starting the backend service and Envoy proxy..."

# Start the backend service, naming it "backend" on the network
docker run -d --name backend-service --network $NETWORK_NAME --network-alias backend \
  backend-service-image

# Start Envoy, mounting the config file. We expose port 8080.
docker run -d --name envoy-proxy --network $NETWORK_NAME \
  -v "$(pwd)/$DEMO_DIR/envoy.yaml:/etc/envoy/envoy.yaml" \
  -p "8080:10000" \
  envoyproxy/envoy:v1.28-latest

echo "--> Waiting 5s for services to initialize..."
sleep 5

echo "--> 4. Sending a request to Envoy (port 8080)..."
RESPONSE=$(curl -s http://localhost:8080)

echo "--> Verifying the response from Envoy..."
EXPECTED_RESPONSE="Hello from backend service!"
if [ "$RESPONSE" == "$EXPECTED_RESPONSE" ]; then
  echo "--> SUCCESS: Received the expected '$EXPECTED_RESPONSE' response."
  echo "--- Response ---"
  echo "$RESPONSE"
  echo "---"
else
  echo "--> FAILURE: Expected '$EXPECTED_RESPONSE' but got '$RESPONSE'."
  exit 1
fi

echo "--> Envoy demo completed successfully!"
