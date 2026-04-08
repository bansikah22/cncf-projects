#!/bin/bash

# This script runs a verifiable Fluentd demo, showing how it
# can collect logs from a file written by another container.

set -e

DEMO_DIR="fluentd/demo"
LOG_VOLUME="fluentd-log-volume"

# Cleanup function to be called on script exit and start
cleanup() {
  echo "--> Cleaning up any previous runs..."
  docker stop logger-app fluentd-service || true
  docker rm logger-app fluentd-service || true
  docker volume rm $LOG_VOLUME || true
}
trap cleanup EXIT
cleanup

echo "--> 1. Creating a shared Docker volume for logs..."
docker volume create $LOG_VOLUME

echo "--> 2. Building the logging application image..."
docker build -t logger-app-image "$DEMO_DIR"

echo "--> 3. Starting the application and Fluentd containers..."

# Start the application, mounting the shared volume to /logs
docker run -d --name logger-app \
  -v "$LOG_VOLUME:/logs" \
  logger-app-image

# Start Fluentd, mounting the same volume so it can read the logs
# We also mount the config file.
docker run -d --name fluentd-service \
  --user root \
  -v "$LOG_VOLUME:/logs" \
  -v "$(pwd)/$DEMO_DIR/fluent.conf:/fluentd/etc/fluent.conf" \
  fluent/fluentd:v1.14-1

echo "--> Waiting 10s for logs to be generated and collected..."
sleep 10

echo "--> 4. Verifying Fluentd logs..."
FLUENTD_LOGS=$(docker logs fluentd-service 2>&1)

# Check if the logs from our app appear in Fluentd's output
if echo "$FLUENTD_LOGS" | grep -q 'app.log: {"message":"Log entry'; then
  echo "--> SUCCESS: Found application logs in the Fluentd output."
  echo "--- Log Snippet ---"
  echo "$FLUENTD_LOGS" | grep 'app.log' | tail -n 2
  echo "---"
else
  echo "--> FAILURE: Did not find application logs in the Fluentd output."
  echo "Full logs: $FLUENTD_LOGS"
  exit 1
fi

echo "--> Fluentd demo completed successfully!"
# Cleanup will be handled automatically by the trap
