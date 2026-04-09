#!/bin/bash

# This script provides a verifiable, self-contained demo of Argo CD's GitOps capabilities.
# It runs a Gitea server inside the cluster to act as a local Git repository, removing
# all external network dependencies and ensuring a reliable demonstration.

set -e

DEMO_DIR="argocd/demo"
KUSTOMIZE_PATCH_FILE="$DEMO_DIR/guestbook-gitops/overlays/staging/patch.yaml"

# Cleanup function
cleanup() {
  echo "--> Cleaning up..."
  git checkout -- "$KUSTOMIZE_PATCH_FILE"
  minikube delete --profile argocd-demo || true
}
trap cleanup EXIT
cleanup

echo "--> 1. Creating a minikube cluster with increased resources..."
minikube start --profile argocd-demo --cpus 4 --memory 8192

echo "--> 2. Installing Argo CD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.0/manifests/install.yaml

echo "--> 3. Installing Gitea (in-cluster Git server)..."
kubectl create namespace gitea
kubectl apply -n gitea -f "$DEMO_DIR/gitea.yaml"

echo "--> 4. Waiting for Argo CD and Gitea to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
kubectl wait --for=condition=available --timeout=600s deployment/gitea -n gitea
echo "--> All services are ready."

echo "--> 5. Initializing the in-cluster Git repository..."
# This is complex: we exec into a temporary git client pod to push to our gitea server.
kubectl run git-client --image=alpine/git --restart=Never --command -- sleep 3600
kubectl wait --for=condition=ready pod/git-client
# Copy our gitops repo into the client pod
kubectl cp "$DEMO_DIR/guestbook-gitops" git-client:/tmp/
# Exec into the pod to configure git and push to gitea
kubectl exec git-client -- /bin/sh -c "
  apk add openssh-client curl
  # Wait for Gitea to be ready
  until curl -s http://gitea.gitea.svc:3000; do
    echo 'Waiting for Gitea...'
    sleep 2
  done
  git config --global user.email 'demo@example.com'
  git config --global user.name 'Demo User'
  cd /tmp/guestbook-gitops
  git init
  git add .
  git commit -m 'Initial commit'
  # We are pushing over HTTP to the Gitea service's internal cluster DNS name
  git remote add origin http://gitea.gitea.svc:3000/gitea/guestbook.git
  git push -u origin master
"
# We don't need the client pod anymore
kubectl delete pod git-client

echo "--> 6. Updating Argo CD Application to use the in-cluster repo..."
# This sed command replaces the repoURL in the application manifest
sed -i 's|https://github.com/bansikah22/cncf-projects.git|http://gitea.gitea.svc:3000/gitea/guestbook.git|' "$DEMO_DIR/application.yaml"

echo "--> 7. Deploying guestbook app via Argo CD..."
kubectl apply -f "$DEMO_DIR/application.yaml"

echo "--> 8. Verifying the application syncs and is healthy..."
# We need to authenticate with argo again
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
kubectl -n argocd port-forward svc/argocd-server 8080:443 &
ARGOCD_PORT_FORWARD_PID=$!
sleep 5
argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure
kill "$ARGOCD_PORT_FORWARD_PID"
# Now wait for the app
argocd app wait guestbook --sync --health --timeout 300
echo "--> SUCCESS: Application has synced successfully."

echo "--> 9. Verifying the deployment has 2 replicas..."
REPLICAS=$(kubectl get deployment -n guestbook guestbook-ui -o jsonpath='{.spec.replicas}')
if [ "$REPLICAS" -ne 2 ]; then
  echo "--> FAILURE: Expected 2 replicas but found $REPLICAS."
  exit 1
fi
echo "--> SUCCESS: Deployment has 2 replicas."

echo "--> Argo CD GitOps demo completed successfully!"
