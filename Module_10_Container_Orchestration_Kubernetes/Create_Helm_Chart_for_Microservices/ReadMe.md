# Reusable Microservice Helm Chart

## Demo project

**Technologies:** Helm 3/4, Kubernetes, YAML, Docker container images, NGINX

This project packages the repeated Kubernetes resources needed by a stateless microservice: a `Deployment`, `Service`, optional `Ingress`, and optional Helm connection test. It uses a single chart with values files for an NGINX demonstration and three Online Boutique microservice examples.

## Architecture

```text
Client
  │
  ├─ optional HTTP Ingress
  │       │
  └───────▼
       Service
          │
          ▼
  Deployment → replicated application Pods
```

Each release is isolated by standard Helm labels. `fullnameOverride` is available for services that must retain a fixed DNS name for inter-service communication.

## Chart contents

| Path | Purpose |
| --- | --- |
| `templates/deployment.yaml` | Creates the application Pods with an image, environment variables, optional HTTP probes, and resource limits. |
| `templates/service.yaml` | Exposes the Pods through a Kubernetes Service. |
| `templates/ingress.yaml` | Creates an Ingress only when `ingress.enabled=true`. |
| `templates/tests/test-connection.yaml` | Helm test hook that curls the HTTP service when enabled. |
| `values.schema.json` | Rejects missing or malformed required chart values before rendering. |
| `values/` | Valid example overrides for recommendation, product-catalog, and email services. |
| `rendered-manifests.yaml` | Generated default render for review; do not edit by hand. |

`config.yaml` is a standalone, valid Service example retained for comparison. The Helm chart source of truth is `Chart.yaml`, `values.yaml`, and `templates/`.

## Default behavior

The default release deploys `nginxinc/nginx-unprivileged:1.27.4-alpine` on port `8080`, with conservative resource requests/limits and HTTP readiness/liveness probes.

- Publishing an Ingress is disabled by default.
- The Helm connection test is enabled by default for the HTTP NGINX example.
- The Online Boutique service values disable HTTP probes and the curl hook because these examples expose gRPC-oriented workloads rather than this chart's generic HTTP contract.

## Validate locally

From this directory, validate the chart without contacting a Kubernetes cluster:

```sh
helm lint .
helm lint . -f values/recommendation-service-values.yaml
helm template nginx-demo . > rendered-manifests.yaml
kubectl apply --dry-run=client --validate=true -f rendered-manifests.yaml
```

Use the same lint/template commands with `productcatalog-service.yaml` and `email-service-values.yaml` to validate their overrides.

## Deploy the NGINX demo

First verify the active target cluster and create a disposable namespace:

```sh
kubectl config current-context
kubectl create namespace microservice-demo
```

Install and verify the release:

```sh
helm upgrade --install nginx-demo . --namespace microservice-demo --create-namespace
kubectl rollout status deployment/nginx-demo -n microservice-demo
helm test nginx-demo -n microservice-demo
kubectl port-forward service/nginx-demo 8080:8080 -n microservice-demo
```

With the port-forward running, browse to `http://localhost:8080` or use an HTTP client. Clean up after the demonstration:

```sh
helm uninstall nginx-demo -n microservice-demo
kubectl delete namespace microservice-demo
```

## Install a service-specific configuration

The examples use fixed service names so that the Online Boutique services can refer to each other by DNS. Install each one as a separate release in the same namespace:

```sh
helm upgrade --install productcatalog . -n microservice-demo -f values/productcatalog-service.yaml
helm upgrade --install recommendation . -n microservice-demo -f values/recommendation-service-values.yaml
helm upgrade --install email . -n microservice-demo -f values/email-service-values.yaml
```

The examples are chart-rendering references, not a complete Online Boutique installation: they do not include every dependency, configuration setting, or production health endpoint required by that application.

## Enable Ingress intentionally

Ingress requires a controller and DNS name that you control. It is disabled by default. To render it safely, supply both an enabled flag and host:

```sh
helm template nginx-demo . --set ingress.enabled=true --set ingress.host=nginx.example.test
```

For real use, configure TLS and an appropriate `ingress.className`; do not expose internal services unless they need public routing.

## Security and production notes

- Keep credentials, tokens, and private configuration out of values files; use Kubernetes Secrets or an external secret manager.
- Pin reviewed image tags or, preferably, immutable image digests for production deployments.
- Set service-specific requests, limits, probes, and NetworkPolicies based on measured workload behavior.
- Use namespace isolation, RBAC, TLS, and policy controls appropriate for the target environment.

## Verification status

The default NGINX configuration plus all three service overrides have passed `helm lint`, `helm template`, and `kubectl apply --dry-run=client --validate=true`. No cluster resources, images, or external services were created during these validations. A live Helm install and `helm test` still require an accessible Kubernetes cluster.