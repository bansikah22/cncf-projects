#!/bin/bash

# This script runs a verifiable Jaeger demo using individual Docker commands
# and the OpenTelemetry standard.

set -e

DEMO_DIR="jaeger/demo"
NETWORK_NAME="jaeger-net"

# Cleanup function to be called on script exit
cleanup() {
  echo "--> Cleaning up..."
  docker stop jaeger frontend backend || true
  docker rm jaeger frontend backend || true
  docker network rm $NETWORK_NAME || true
}
trap cleanup EXIT

echo "--> 1. Setting up Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || true

echo "--> 2. Building images for frontend and backend services..."
docker build -t frontend-app -f "$DEMO_DIR/Dockerfile.frontend" "$DEMO_DIR"
docker build -t backend-app -f "$DEMO_DIR/Dockerfile.backend" "$DEMO_DIR"

echo "--> 3. Starting Jaeger, Frontend, and Backend containers..."
# Start Jaeger
docker run -d --name jaeger --network $NETWORK_NAME \
  -p 16686:16686 \
  -p 4317:4317 \
  jaegertracing/all-in-one:latest

# Start Backend
docker run -d --name backend --network $NETWORK_NAME \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=jaeger:4317 \
  -e OTEL_SERVICE_NAME=backend-service \
  backend-app

# Start Frontend
docker run -d --name frontend --network $NETWORK_NAME \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=jaeger:4317 \
  -e OTEL_SERVICE_NAME=frontend-service \
  -p 8081:8081 \
  frontend-app

echo "--> Waiting for services to initialize..."
sleep 20

echo "--> 4. Sending a request to the frontend to generate a trace..."
curl http://localhost:8081/

echo "--> Waiting for the trace to be exported..."
sleep 15

echo "--> 5. Verifying that the distributed trace was received by Jaeger..."
JAEGER_API_URL="http://localhost:16686/api/traces?service=frontend-service&limit=1"
TRACE_DATA=$(curl -s "$JAEGER_API_URL")

if ! echo "$TRACE_DATA" | grep -q '"traceID"'; then
  echo "--> FAILURE: Did not find any traces for frontend-service."
  echo "Full API response: $TRACE_DATA"
  exit 1
fi

SPAN_COUNT=$(echo "$TRACE_DATA" | grep -o '"spanID"' | wc -l)
if [ "$SPAN_COUNT" -ge 2 ]; then
  echo "--> SUCCESS: Found a trace with $SPAN_COUNT spans."
else
  echo "--> FAILURE: Expected at least 2 spans, but found $SPAN_COUNT."
  echo "Full API response: $TRACE_DATA"
  exit 1
fi

echo "--> Jaeger demo completed successfully!"
# Cleanup will be handled automatically by the trap
