#!/bin/bash

# NOTE: The commands below are for demonstrating the `crictl` workflow with CRI-O.
# They require a properly configured CRI-O installation and root privileges, which
# may not be available in all environments. The expected output is documented
# in the main README.md.

# The `crictl` command requires a configuration file to know which CRI socket to connect to.
# This would typically be created at /etc/crictl.yaml
# ---
# runtime-endpoint: "unix:///var/run/crio/crio.sock"
# image-endpoint: "unix:///var/run/crio/crio.sock"
# timeout: 10
# debug: false
# ---

echo "--> This script demonstrates the steps to create a pod and container with crictl."
echo "--> All commands are commented out due to environmental restrictions."

# POD_CONFIG="pod-sandbox.yaml"
# CONTAINER_CONFIG="container-config.json"
# IMAGE="docker.io/library/nginx:alpine"

# 1. Pull the image
# echo "--> Pulling NGINX image..."
# sudo crictl pull $IMAGE

# 2. Create the Pod Sandbox
# This step creates the pod's namespaces and cgroups.
# The config file defines metadata like the pod name and namespace.
# echo "--> Creating Pod Sandbox..."
# sudo crictl runp $POD_CONFIG

# 3. Create the Container
# This creates a container within the pod sandbox created above.
# The config file references the pod ID and the image to use.
# echo "--> Creating Container..."
# sudo crictl create $(sudo crictl pods -q) $CONTAINER_CONFIG $POD_CONFIG

# 4. List Pods and Containers
# echo "--> Listing Pods:"
# sudo crictl pods
# echo "--> Listing Containers:"
# sudo crictl ps -a

# 5. Stop and Remove
# POD_ID=$(sudo crictl pods -q)
# CONTAINER_ID=$(sudo crictl ps -a -q)
# echo "--> Stopping container $CONTAINER_ID..."
# sudo crictl stop $CONTAINER_ID
# echo "--> Removing container $CONTAINER_ID..."
# sudo crictl rm $CONTAINER_ID
# echo "--> Stopping pod sandbox $POD_ID..."
# sudo crictl stopp $POD_ID
# echo "--> Removing pod sandbox $POD_ID..."
# sudo crictl rmp $POD_ID

echo "--> Demo script finished."
