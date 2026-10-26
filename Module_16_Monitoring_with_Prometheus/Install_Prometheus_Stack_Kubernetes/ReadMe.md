Workflow Breakdown
Infrastructure Provisioning (eksctl): The sequence begins by abstracting AWS CloudFormation to build an Elastic Kubernetes Service (EKS) control plane and associated worker node groups.

Application Deployment: Applying config-microservices.yaml deploys the target workload (e.g., a multi-tier application) into the default K8s namespace.

Helm Package Management: Helm is utilized to add the official Prometheus community repository. Several typographical errors (promethues) were attempted before successfully registering prometheus-community.

Observability Stack Installation: The kube-prometheus-stack is deployed into a dedicated monitoring namespace. This single chart installs the Prometheus Operator, Prometheus, Alertmanager, Grafana, kube-state-metrics, and node-exporter, establishing a comprehensive metric scraping and visualization engine.

State Inspection & Extraction: The final commands query the Kubernetes API to inspect deployed resources (CRDs, StatefulSets, ConfigMaps) and extract specific configurations (alert.yaml, secret.yaml, config.yaml) for local modification or archival. The initial attempts failed due to missing namespace declarations (-n monitoring) and malformed resource declarations (pod/secret), which were eventually corrected.






# AWS EKS Microservices Monitoring Stack

This repository contains the configuration and command history for bootstrapping an Amazon EKS cluster, deploying a microservices architecture, and installing a complete Prometheus/Grafana observability stack via Helm.

## Prerequisites
- AWS CLI configured with appropriate IAM permissions
- `eksctl` installed
- `kubectl` installed
- `helm` installed

## 1. Cluster Provisioning & Verification
Bootstrap the EKS cluster and verify that the worker nodes have registered with the control plane.

```bash
# Provision EKS cluster (control plane and managed node groups)
eksctl create cluster
# Verify worker node readiness
kubectl get node
```

## 2. Application Workload Deployment
Deploy the primary microservices application payload into the default namespace.

```bash
# Apply the declarative microservices manifest
kubectl apply -f config-microservices.yaml

# Monitor pod creation and verify Running state
kubectl get pod
```


3. Helm Configuration & Stack Installation
Configure the Helm package manager and deploy the kube-prometheus-stack into an isolated namespace. This stack utilizes the Operator pattern to manage Prometheus and Alertmanager instances natively within Kubernetes.

```bash
# Add the official Prometheus Community Helm repository
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)

# Create an isolated namespace for monitoring tools to prevent resource pollution
kubectl create namespace monitoring

# Deploy the complete observability stack (Prometheus, Grafana, Alertmanager)
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
```


4. Resource Inspection
Verify the deployment of all monitoring components, including Custom Resource Definitions (CRDs) installed by the Prometheus Operator.
```bash
# Inspect all primary resources within the monitoring namespace
kubectl get all -n monitoring

# Verify mounted configuration files and dashboards
kubectl get configmap -n monitoring

# Verify credentials (e.g., Grafana admin password) and TLS certificates
kubectl get secret -n monitoring

# List Custom Resource Definitions (e.g., ServiceMonitors, Prometheuses)
kubectl get crd -n monitoring

# Check the status of database/stateful workloads (Prometheus, Alertmanager)
kubectl get statefulset -n monitoring

# Check stateless deployments (Grafana, Operator, kube-state-metrics)
kubectl get deployment -n monitoring
```


5. Configuration Extraction
Extract live cluster configurations into local YAML manifests. This is highly useful for auditing current state, migrating to Infrastructure as Code (IaC), or backing up specific rules and secrets.
``` bash
# Export the Alertmanager StatefulSet configuration details for review
kubectl describe statefulset alertmanager-monitoring-kube-prometheus-alertmanager -n monitoring > alert.yaml

# Extract the main Prometheus secret manifest
kubectl get secret prometheus-monitoring-kube-prometheus-prometheus -n monitoring -o yaml > secret.yaml

# Extract the Prometheus alerting and recording rules configuration
kubectl get secret prometheus-monitoring-kube-prometheus-prometheus-rulefiles-0 -n monitoring -o yaml > config.yaml
```

