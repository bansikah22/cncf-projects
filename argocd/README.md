# Argo CD Exploration

[`Argo CD`](https://argo-cd.readthedocs.io/en/stable/) is a declarative, GitOps continuous delivery tool for Kubernetes.

## What is GitOps?

**GitOps** is a way of doing Continuous Delivery where Git is the "single source of truth." Instead of manually running `kubectl` commands, you declare the desired state of your system in a Git repository. Argo CD's job is to make your cluster's state match the state in Git.

## Verifiable Demo: A Real-World GitOps Workflow

This demo provides a robust, verifiable example of Argo CD's core functionality using your existing public GitHub repository as the source of truth for your application's configuration.

The entire process will be driven through the Argo CD web interface, just as you would in a real-world scenario.

## Manual Walkthrough

The following steps will guide you through setting up and observing a complete GitOps workflow.

### Step 1: Start Minikube & Install Argo CD
This will start your local cluster and deploy the Argo CD components.

```bash
# Start Minikube with sufficient resources
minikube start --profile argocd-demo --cpus 4 --memory 8192

# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.0/manifests/install.yaml

# Wait for Argo CD to be ready (this may take several minutes)
echo "--> Waiting for Argo CD..."
kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n argocd
echo "--> Argo CD is ready."
```

### Step 2: Deploy the Application via the Argo CD UI
It's time to connect Argo CD to your `kubesrv-gitops` GitHub repository.

**Open a new terminal** and run this command to forward the Argo CD server. **Leave it running.**
```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

1.  In your **original terminal**, get the admin password:
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
    ```
2.  Open your browser to `https://localhost:8080`. (Proceed past the browser security warning).
3.  Log in with the username `admin` and the password you just retrieved.
4.  Click **+ NEW APP**.
5.  For **Application Name**, enter `kubesrv`.
6.  For **Project**, select `default`.
7.  For **Sync Policy**, select `Automatic`.
8.  Under **Source**, for **Repository URL**, enter `https://github.com/bansikah22/kubesrv-gitops.git`.
9.  For **Path**, enter `apps/kubesrv`.
10. Under **Destination**, for **Cluster URL**, select `https://kubernetes.default.svc`.
11. For **Namespace**, enter `default`.
12. Click **CREATE** at the top of the page.

You will now see the `kubesrv` application card. After a moment, it will automatically sync, and all the resources will turn green and healthy. You can click on the card to see the resource tree.

### Step 3: The GitOps Loop - Push a Change
Let's simulate a developer scaling the application by pushing a change to the GitHub repository.

1.  In your **local clone** of the `kubesrv-gitops` repository, open the file `apps/kubesrv/deployment.yaml`.
2.  Change the `replicas` field from `1` to `3`.
3.  Commit and push this change to the `master` branch on GitHub.
4.  Go back to the Argo CD UI in your browser. Click the **Refresh** button on the `kubesrv` application. Within a few moments, Argo CD will detect the change, show the application as `OutOfSync`, and then automatically start syncing to apply the change.
5.  Verify the change from your terminal:
    ```bash
    kubectl get deployment -n default kubesrv -o jsonpath='{.spec.replicas}'
    ```
    This command should now output `3`.

### Step 4: Cleanup
When you are finished, stop the `port-forward` process (Ctrl+C). Then, run this command to delete the cluster.

```bash
minikube delete --profile argocd-demo
```
