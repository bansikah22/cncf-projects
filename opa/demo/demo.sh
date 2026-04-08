#!/bin/bash

# This script provides a verifiable demo of Open Policy Agent (OPA)
# by using the 'opa' CLI to validate Kubernetes manifests.

set -e

DEMO_DIR="opa/demo"

# Create a local bin directory and add it to the PATH
mkdir -p ./bin
export PATH=$PATH:$(pwd)/bin

# --- Helper Function ---
install_opa_cli() {
  curl -L -o ./bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
  chmod +x ./bin/opa
}

# 1. Ensure OPA CLI is installed
if ! command -v "opa" &> /dev/null; then
  echo "--> 'opa' command not found. Installing..."
  install_opa_cli
else
  echo "--> 'opa' is already installed."
fi

# 2. Test the compliant deployment
echo "--> Verifying compliant deployment (expecting 'true')..."
RESULT_COMPLIANT=$(opa eval --input "$DEMO_DIR/compliant-deployment.yaml" --data "$DEMO_DIR/policy.rego" "data.kubernetes.validation.allow" --format raw)

echo "--- Result ---"
echo "$RESULT_COMPLIANT"
echo "---"

if [ "$RESULT_COMPLIANT" != "true" ]; then
    echo "--> FAILURE: Expected 'true' but got '$RESULT_COMPLIANT'"
    exit 1
fi
echo "--> SUCCESS: OPA evaluation returned 'true', as expected."


# 3. Test the NON-compliant deployment
echo "--> Verifying NON-compliant deployment (expecting 'undefined')..."
# We expect this command to return an empty result, which indicates the 'allow' rule was not met.
RESULT_NON_COMPLIANT=$(opa eval --input "$DEMO_DIR/non-compliant-deployment.yaml" --data "$DEMO_DIR/policy.rego" "data.kubernetes.validation.allow" --format raw)

echo "--- Result ---"
if [ "$RESULT_NON_COMPLIANT" != "false" ]; then
    echo "--> FAILURE: Expected 'false' but got '$RESULT_NON_COMPLIANT'"
    exit 1
fi
echo "--> SUCCESS: OPA evaluation returned 'false', as expected."

echo "--> OPA demo completed successfully!"
