#!/bin/bash

# This script runs a verifiable OpenTelemetry demo featuring the OTel Collector.

set -e

DEMO_DIR="opentelemetry/demo"
NETWORK_NAME="otel-net"

# Cleanup function to be called on script exit and start
cleanup() {
  echo "--> Cleaning up any previous runs..."
  # Capture logs from failed containers for debugging before removing them
  if [ "$(docker ps -a -q -f name=otel-collector)" ]; then
    echo "--- OTel Collector logs ---"
    docker logs otel-collector || true
  fi
  docker stop jaeger-otel-demo otel-collector go-app || true
  docker rm jaeger-otel-demo otel-collector go-app || true
  docker network rm $NETWORK_NAME || true
}
trap cleanup EXIT
cleanup # Run cleanup at the start to ensure a clean state

echo "--> 1. Setting up Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || true

echo "--> 2. Building the Go application image..."
docker build -t go-app-otel "$DEMO_DIR"

echo "--> 3. Starting services and discovering IP addresses..."
docker run -d --name jaeger-otel-demo --network $NETWORK_NAME -p 16687:16686 jaegertracing/all-in-one:latest
JAEGER_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "otel-net").IPAddress}}' jaeger-otel-demo)
echo "Jaeger started with IP: $JAEGER_IP"

CONFIG_TEMPLATE_PATH="$DEMO_DIR/collector-config.yaml"
TEMP_CONFIG_PATH="$DEMO_DIR/collector-config-temp.yaml"
# Use a different sed delimiter (#) to avoid issues with special characters in variables
sed "s#jaeger:4317#${JAEGER_IP}:4317#g" "$CONFIG_TEMPLATE_PATH" > "$TEMP_CONFIG_PATH"

echo "--> Verifying temporary collector config:"
cat "$TEMP_CONFIG_PATH"
echo "---"

docker run -d --name otel-collector --network $NETWORK_NAME \
  -v "$(pwd)/$TEMP_CONFIG_PATH:/etc/otelcol/config.yaml" \
  -p 13133:13133 \
  otel/opentelemetry-collector:latest
COLLECTOR_IP=$(docker inspect -f '{{(index .NetworkSettings.Networks "otel-net").IPAddress}}' otel-collector)
echo "OTel Collector started with IP: $COLLECTOR_IP"
rm "$TEMP_CONFIG_PATH"

echo "--> Waiting for OTel Collector to be healthy..."
RETRY_COUNT=0
MAX_RETRIES=12
until curl -s "http://localhost:13133/" | grep -q "Server available"; do
  RETRY_COUNT=$((RETRY_COUNT+1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "--> FAILURE: OTel Collector did not become healthy in time."
    exit 1
  fi
  echo "Collector not ready yet, waiting 5s... (Attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 5
done
echo "Collector is healthy!"

docker run -d --name go-app --network $NETWORK_NAME \
  -e OTEL_EXPORTER_OTLP_ENDPOINT="$COLLECTOR_IP:4317" \
  -p 8080:8080 \
  go-app-otel

echo "--> All services started. Waiting 20s for all connections to establish."
sleep 20

echo "--> 4. Sending a request to the Go app..."
curl http://localhost:8080/
sleep 15 # Give trace time to propagate

echo "--> 5. Verifying the pipeline..."
echo "--> 5a. Checking OTel Collector logs..."
COLLECTOR_LOGS=$(docker logs otel-collector 2>&1)
if echo "$COLLECTOR_LOGS" | grep -q "go-app-service"; then
  echo "--> SUCCESS: Trace found in Collector logs."
else
  echo "--> FAILURE: Trace not found in Collector logs."
  exit 1
fi

echo "--> 5b. Checking Jaeger for the trace..."
JAEGER_API_URL="http://localhost:16687/api/traces?service=go-app-service&limit=1"
TRACE_DATA=$(curl -s "$JAEGER_API_URL")
if echo "$TRACE_DATA" | grep -q '"traceID"'; then
  echo "--> SUCCESS: Trace found in Jaeger."
else
  echo "--> FAILURE: Trace not found in Jaeger."
  exit 1
fi

echo "--> OpenTelemetry demo completed successfully!"
