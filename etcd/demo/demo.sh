#!/bin/bash

ETCDCTL_API=3

# Put a key-value pair
docker exec etcd-demo etcdctl put mykey "this is a test"

# Get the value
docker exec etcd-demo etcdctl get mykey

# Watch for changes (in the background)
docker exec etcd-demo etcdctl watch mykey &
WATCH_PID=$!
sleep 1

# Update the key
docker exec etcd-demo etcdctl put mykey "this is a new value"
sleep 1
# Kill the watch process
kill $WATCH_PID
