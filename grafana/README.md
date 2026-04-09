# Grafana Exploration

[`Grafana`](https://grafana.com/) is an open-source platform for monitoring and observability. It allows you to query, visualize, alert on, and explore your metrics no matter where they are stored.

## What is Grafana?

While tools like Prometheus are excellent for collecting and storing metrics, they are not primarily designed for visualization. Grafana is the de-facto standard for creating beautiful, complex, and highly useful dashboards from a wide variety of data sources, including Prometheus.

## How Grafana Works

Grafana runs as a server that you can access through a web browser. Inside Grafana, you configure:

1.  **Data Sources:** You tell Grafana how to connect to your databases (like Prometheus).
2.  **Dashboards:** A collection of one or more panels.
3.  **Panels:** A specific visualization (like a graph or a table) configured with a query.

```mermaid
graph TD
    A[Prometheus] -- Scrapes Metrics --> B(Your Application);
    C[Grafana] -- Queries --> A;
    D[User's Browser] -- Views Dashboard --> C;
```

## Verifiable Demo: Visualizing Prometheus Metrics

This demo will show how to install Prometheus and Grafana into a single cluster and then use Grafana to visualize metrics collected by Prometheus.

### Manual Walkthrough

#### Step 1: Start Minikube

```bash
minikube start --profile grafana-demo --cpus 4 --memory 8192
```

#### Step 2: Install Prometheus
We will use the standard Helm chart to install a Prometheus instance.

```bash
# Add the Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus into a 'monitoring' namespace
kubectl create namespace monitoring
helm install prometheus prometheus-community/prometheus --namespace monitoring
```

#### Step 3: Install Grafana

```bash
# Add the Grafana Helm repository
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Grafana
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set persistence.enabled=true \
  --set adminPassword='admin'
```

#### Step 4: Access the Grafana UI

```bash
# Port-forward the Grafana service. Open a new terminal for this and leave it running.
kubectl -n monitoring port-forward svc/grafana 3000:80

# Open your browser to http://localhost:3000
# Log in with username 'admin' and password 'admin'.
```

#### Step 5: Add Prometheus as a Data Source

1.  In the Grafana UI, go to the **Connections** section (the four squares icon on the left).
2.  Click **Add new connection**.
3.  Search for **Prometheus** and select it.
4.  For the **Prometheus server URL**, enter the in-cluster address of the Prometheus server: `http://prometheus-server.monitoring.svc.cluster.local`.
5.  Click **Save & test**. You should see a green checkmark indicating the data source is working.

#### Step 6: Create a Dashboard

1.  Click the **+** icon in the top-right corner and select **New Dashboard**.
2.  Click **Add visualization**.
3.  In the query editor at the bottom, make sure your **Prometheus** data source is selected.
4.  In the query field, enter the following PromQL query to get the container CPU usage:
    ```promql
    sum(rate(container_cpu_usage_seconds_total{namespace="monitoring"}[5m])) by (pod)
    ```
5.  On the right side of the screen, under "Panel options," set the **Title** to "CPU Usage by Pod".
6.  Click **Apply** in the top-right corner.

You will now see a panel on your dashboard showing the CPU usage of the pods in the `monitoring` namespace.

#### Step 7: Cleanup

```bash
minikube delete --profile grafana-demo
```
