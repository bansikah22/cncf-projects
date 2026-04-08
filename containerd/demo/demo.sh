#!/bin/bash

# NOTE: The following commands are for demonstration purposes.
# They require interactive `sudo` access to the containerd socket,
# which may not be available in all execution environments.
# The expected output is documented in the main README.md.

# Define the image and container names
# IMAGE_NAME="docker.io/library/redis:alpine"
# CONTAINER_ID="redis-demo-ctr"

# 1. Pull the image
# echo "--> Pulling image: $IMAGE_NAME"
# sudo ctr images pull $IMAGE_NAME

# 2. Run the container
# echo "--> Running container with ID: $CONTAINER_ID"
# sudo ctr run -d --net-host $IMAGE_NAME $CONTAINER_ID

# Wait a moment for the container to start
# sleep 5

# 3. List the running containers
# echo "--> Listing running containers:"
# sudo ctr containers list

# 4. Stop and delete the container
# echo "--> Stopping and deleting the container..."
# sudo ctr tasks kill $CONTAINER_ID
# sudo ctr containers delete $CONTAINER_ID

echo "--> Demo script finished (commands commented out due to environment restrictions)."
