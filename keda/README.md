# KEDA Exploration

[`KEDA`](https://keda.sh/) is a **K**ubernetes-based **E**vent **D**riven **A**utoscaler. It provides event-driven autoscaling for your Kubernetes workloads. KEDA is a CNCF Graduated project.

## What Problem Does KEDA Solve?

The standard Kubernetes Horizontal Pod Autoscaler (HPA) works very well for scaling workloads based on CPU and memory utilization. However, it does not have a built-in way to scale based on external or custom metrics, such as the number of messages in a queue, the number of events in a stream, or the result of a database query.

Applications that process jobs from a queue are a classic example. If there are no messages in the queue, you might want to scale your worker pods down to zero to save resources. When a burst of messages arrives, you need to scale up quickly to process them.

KEDA extends the Kubernetes HPA to do exactly this. It acts as a "metrics adapter," providing metrics from various event sources to the HPA so it can scale your deployments accordingly.

### Use Cases
*   **Message Queues:** Scale a worker deployment based on the number of messages in a RabbitMQ, Kafka, or SQS queue.
*   **Databases:** Scale a data processor based on the number of rows in a PostgreSQL or MySQL table.
*   **Cron:** Scale a workload up on a specific schedule (e.g., once every hour) to perform a batch job, and scale it down to zero when finished.
*   **Monitoring:** Scale based on a Prometheus query.

## Architecture & Components

KEDA works by adding a few key components to your cluster.

1.  **KEDA Operator:** This is the main KEDA controller. It consists of two key parts:
    *   **`keda-operator`:** This component watches for `ScaledObject` custom resources.
    *   **`keda-metrics-apiserver`:** This component exposes the external metrics from your event sources to the standard Kubernetes HPA.
2.  **`ScaledObject`:** This is the custom resource you create to define how your workload should be scaled. In a `ScaledObject`, you specify:
    *   The `scaleTargetRef` (e.g., the name of the `Deployment` you want to scale).
    *   The `triggers`, which define the event source (e.g., a RabbitMQ queue), the connection details, and the threshold for scaling.
    *   `minReplicaCount` and `maxReplicaCount`. A key feature of KEDA is that you can set `minReplicaCount: 0`.

When you create a `ScaledObject`, the KEDA Operator creates a standard `HorizontalPodAutoscaler` (HPA) resource for you and starts feeding it metrics from your chosen event source.

```mermaid
graph TD
    subgraph "Kubernetes Control Plane"
        A(HPA Controller);
    end

    subgraph "KEDA Components"
        B(KEDA Operator);
        C(Metrics Server);
    end
    
    D[Event Source: RabbitMQ];
    E(Deployment);

    A -- "Get Metrics" --> C;
    A -- "Scale" --> E;
    B -- "Creates/Manages" --> A;
    C -- "Polls for Metrics" --> D;
    
    F(User) -- "Creates" --> G(ScaledObject);
    B -- "Watches" --> G;
```


## Verifiable Demo: Scaling on a RabbitMQ Queue

This demo will provide a realistic example of KEDA scaling a worker deployment based on the number of messages in a RabbitMQ queue.

### Manual Walkthrough

#### Step 1: Start Minikube & Install KEDA
This will start a new cluster and install KEDA using the official Helm chart.

```bash
# Start Minikube
minikube start --profile keda-demo --cpus 4 --memory 8192

# Install KEDA using Helm
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda --namespace keda --create-namespace
```

#### Step 2: Deploy RabbitMQ
We need an event source. We will deploy a simple RabbitMQ instance for our demo.

```bash
# Deploy RabbitMQ
kubectl apply -f https://raw.githubusercontent.com/kedacore/sample-go-rabbitmq/main/deploy/rabbitmq.yaml
```

#### Step 3: Deploy the Consumer App and ScaledObject
Now we deploy our application (the consumer) and the `ScaledObject` that tells KEDA how to scale it.

Create a file named `keda/demo/consumer-deployment.yaml` with the following content. This defines the worker that will process messages and the `ScaledObject` that targets it.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: rabbitmq-conn
type: Opaque
data:
  # The RabbitMQ URL is amqp://user:password@rabbitmq.default.svc.cluster.local:5672
  # It must be base64 encoded
  RabbitMqHost: YW1xcDovL3VzZXI6cGFzc3dvcmRAcmFiYml0bXEuZGVmYXVsdC5zdmMuY2x1c3Rlci5sb2NhbDo1Njcy
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rabbitmq-consumer
  labels:
    app: rabbitmq-consumer
spec:
  replicas: 0 # Start with 0 replicas
  selector:
    matchLabels:
      app: rabbitmq-consumer
  template:
    metadata:
      labels:
        app: rabbitmq-consumer
    spec:
      containers:
      - name: consumer
        image: ghcr.io/kedacore/tests-go-rabbitmq-consumer:latest
        env:
        - name: RABBITMQ_URL_AMQP
          valueFrom:
            secretKeyRef:
              name: rabbitmq-conn
              key: RabbitMqHost
---
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: rabbitmq-scaler
spec:
  scaleTargetRef:
    name: rabbitmq-consumer
  triggers:
  - type: rabbitmq
    metadata:
      queueName: hello
      hostFromEnv: RABBITMQ_URL_AMQP
      mode: QueueLength
      value: "5" # The threshold for scaling
```

Now, apply this to your cluster:
```bash
kubectl apply -f keda/demo/consumer-deployment.yaml
```

#### Step 4: Verify the Initial State (Scale to Zero)
Check the pods. Because there are no messages in the queue, KEDA should keep the deployment scaled to 0 replicas.

```bash
# You should see 'No resources found in default namespace.'
kubectl get pods
```
This is KEDA's "scale-to-zero" feature in action.

#### Step 5: Publish Messages and Watch KEDA Scale Up
Now, let's publish some messages to the queue. We'll run a temporary pod to do this.

```bash
# Deploy a publisher pod that sends 30 messages
kubectl apply -f https://raw.githubusercontent.com/kedacore/sample-go-rabbitmq/main/deploy/publisher.yaml
```

Now, quickly watch your `rabbitmq-consumer` pods. KEDA will detect the messages, see that the count is above the threshold (`5`), and instruct the HPA to scale up the deployment.

```bash
# Watch the consumer pods scale up
kubectl get pods -w
```
You will see the consumer pods being created and started. It may take a minute or two. Because we sent 30 messages and our threshold is 5 (30/5=6), KEDA will scale the deployment up to a maximum of 6 pods to handle the load.

#### Step 6: Verify Scale Down
After the consumer pods have processed all the messages from the queue, KEDA will detect that the queue length has dropped back to 0. After a cooldown period (a few minutes), it will scale the deployment back down to 0 replicas.

Keep the `kubectl get pods -w` command running, and you will eventually see the pods terminate. This proves the entire event-driven scaling loop is working.

#### Step 7: Cleanup
```bash
minikube delete --profile keda-demo
```
