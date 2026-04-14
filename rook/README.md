# Rook Exploration

[`Rook`](https://rook.io/) is an open-source **cloud-native storage orchestrator** for Kubernetes. It turns distributed storage systems like Ceph into self-managing, self-scaling, and self-healing storage services. Rook is a CNCF Graduated project.

## What Problem Does Rook Solve?

Kubernetes is excellent at managing stateless applications, but managing stateful applications that require persistent storage can be complex. Rook solves this by automating the entire lifecycle of a production-grade storage system (like Ceph) directly within your Kubernetes cluster.

### Use Cases
*   **Block Storage (ReadWriteOnce):** Perfect for single-pod databases like PostgreSQL or MySQL.
*   **Shared Filesystem (ReadWriteMany):** Ideal for web servers or applications that need to share data.
*   **Object Storage (S3-compatible):** Great for storing backups, images, and other unstructured data.

## Verifiable Demo: Dynamic Provisioning of Block Storage

This demo will provide a realistic example of using Rook to provide persistent block storage for a MySQL database.

### Manual Walkthrough

#### Step 1: Start Minikube & Get Rook Manifests
This will start a new cluster and clone the specific version of the Rook repository that we will use for the installation.

```bash
# Start Minikube with sufficient resources
minikube start --profile rook-demo --cpus 4 --memory 8192

# Clone the specific version of the Rook repository
git clone --single-branch --branch v1.14.0 https://github.com/rook/rook.git
```

#### Step 2: Install the Rook Operator and Cluster
We will now apply the manifests from the cloned repository. **Crucially, we will use `cluster-test.yaml`, which is designed for single-node test environments like Minikube.**

```bash
# All commands are run from the root of the cncf-projects repository
kubectl apply -f rook/deploy/examples/crds.yaml
kubectl apply -f rook/deploy/examples/common.yaml
kubectl apply -f rook/deploy/examples/operator.yaml

# Apply the test cluster manifest suitable for Minikube
kubectl apply -f rook/deploy/examples/cluster-test.yaml
```

#### Step 3: Verify the Installation
Wait for all the Rook and Ceph pods to be ready. This can take **several minutes**.

```bash
# Watch the pods in the rook-ceph namespace until they are all Running or Completed
kubectl get pods -n rook-ceph -w
```

#### Step 4: Create the StorageClass
Now we create the resources that allow our applications to request storage.

```bash
# The test storageclass uses a different path and name
kubectl apply -f rook/deploy/examples/csi/rbd/storageclass-test.yaml
```

#### Step 5: Create an Application with a PersistentVolumeClaim
We will now deploy a simple MySQL database that requests persistent storage using the `StorageClass` we just created.

```bash
# Apply the MySQL deployment manifest, which is pre-configured with the correct StorageClass
kubectl apply -f rook/demo/mysql.yaml
```

#### Step 6: Verify the Storage
1.  **Check the PVC:** Verify that your `PersistentVolumeClaim` was successfully created and bound.
    ```bash
    kubectl get pvc mysql-pv-claim
    ```
    The status should be `Bound`.

2.  **Check the Pod:** Wait for the MySQL pod to start.
    ```bash
    kubectl get pods -w
    ```
    Once the MySQL pod is `Running`, it has successfully mounted the persistent block storage provided by Rook/Ceph.

#### Step 7: Cleanup
```bash
minikube delete --profile rook-demo
rm -rf rook
```
