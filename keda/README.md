# KEDA Exploration

[`KEDA`](https://keda.sh/) is a Kubernetes-based Event-Driven Autoscaler. It provides the ability to drive the scaling of any container in Kubernetes based on the number of events needing to be processed from a variety of event sources. KEDA is a CNCF Graduated project.

## What Problem Does KEDA Solve?

Kubernetes provides the Horizontal Pod Autoscaler (HPA), which can scale pods based on metrics like CPU and memory utilization. However, many modern applications are event-driven and their load is not directly correlated with CPU/memory. For example, an application's load might depend on the number of messages in a Kafka topic or a RabbitMQ queue.

KEDA extends Kubernetes to provide fine-grained, event-driven autoscaling. It can scale applications from zero pods (when there are no events) up to thousands of instances based on the event load, and then back down to zero, which can significantly reduce costs for idle applications.

## Architecture & Components

KEDA works by acting as a "metrics server" for the Kubernetes HPA. It queries an external event source (like a message queue), gets a metric (e.g., the queue length), and then feeds this metric to the HPA, which then makes the scaling decision.

The main components are:
*   **KEDA Operator:** The main controller that manages KEDA's custom resources.
*   **Metrics Server:** Exposes metrics from event sources to the HPA.
*   **Scalers:** These are the heart of KEDA. Each scaler is a specific integration for an event source (e.g., a Kafka scaler, a Prometheus scaler, etc.). KEDA has a large catalog of built-in scalers.
*   **`ScaledObject` CRD:** A custom resource where you define how your application should be scaled based on a specific event source.

```mermaid
graph TD
    subgraph "External Event Source"
        A[Message Queue / Database / etc.];
    end

    subgraph "Kubernetes Cluster"
        B[KEDA Operator];
        C[KEDA Metrics Server];
        D[Horizontal Pod Autoscaler (HPA)];
        E[Your Application Deployment];
        F[ScaledObject CRD];
    end

    A -- "Event Metric (e.g., Queue Length)" --> C;
    B -- "Watches" --> F;
    B -- "Creates/Manages" --> D;
    C -- "Provides External Metrics" --> D;
    D -- "Scales" --> E;
    F -- "Defines Scaling Rules for" --> E;

```

## Verifiable Demo

> **Demo Status: Unsuccessful**
> A verifiable demo for KEDA was planned but not completed.
