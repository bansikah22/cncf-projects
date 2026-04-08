#!/bin/bash

# This script runs a verifiable Prometheus demo using individual Docker commands.

set -e

DEMO_DIR="prometheus/demo"
NETWORK_NAME="prometheus-net"

# Cleanup function to be called on script exit
cleanup() {
  echo "--> Cleaning up..."
  docker stop prometheus node_exporter web_app || true
  docker rm prometheus node_exporter web_app || true
  docker network rm $NETWORK_NAME || true
}
trap cleanup EXIT

echo "--> 1. Setting up Docker network..."
docker network create $NETWORK_NAME 2>/dev/null || true

echo "--> 2. Building the custom web app image..."
docker build -t my-web-app "$DEMO_DIR"

echo "--> 3. Starting containers..."
# Start Node Exporter
docker run -d --name node_exporter --network $NETWORK_NAME prom/node-exporter:v1.3.1

# Start the custom web app
docker run -d --name web_app --network $NETWORK_NAME my-web-app

# Start Prometheus, mounting the config and connecting to the network
docker run -d --name prometheus --network $NETWORK_NAME -p 9090:9090 \
  -v "$(pwd)/$DEMO_DIR/prometheus.yml:/etc/prometheus/prometheus.yml" \
  prom/prometheus:v2.37.0 \
  --config.file=/etc/prometheus/prometheus.yml

echo "--> Waiting for services to initialize..."
sleep 10

echo "--> 4. Generating metrics by sending requests to the web app..."
# We need the web_app's IP address on the Docker network
WEB_APP_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web_app)
for i in {1..5}; do
  curl -s "http://$WEB_APP_IP:8080" > /dev/null
  echo "Sent request #$i"
  sleep 1
done

echo "--> 5. Verifying that Prometheus has scraped the custom metric..."
sleep 15 # Give Prometheus time to scrape

QUERY_RESULT=$(curl -s -G "http://localhost:9090/api/v1/query" --data-urlencode "query=http_requests_total > 0")

if echo "$QUERY_RESULT" | grep -q '"result":\[{"metric"'; then
  echo "--> SUCCESS: Prometheus has successfully scraped the 'http_requests_total' metric."
  echo "Query result snippet: $(echo $QUERY_RESULT | cut -c 1-100)..."
else
  echo "--> FAILURE: Prometheus did not return the expected metric."
  echo "Full query result: $QUERY_RESULT"
  exit 1
fi

echo "--> Prometheus demo completed successfully!"
# Cleanup will be handled automatically by the trap
