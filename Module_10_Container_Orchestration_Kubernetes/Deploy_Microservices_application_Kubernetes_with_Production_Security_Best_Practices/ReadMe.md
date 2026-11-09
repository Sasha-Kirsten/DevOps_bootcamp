# Kubernetes Microservice Security Baseline

## Demo project

**Technologies:** Kubernetes, Kustomize, Redis, NGINX, Linux, and any conformant Kubernetes cluster such as Linode Kubernetes Engine (LKE).

This project is a small, runnable baseline for presenting Kubernetes deployment and security practices. It deploys:

- a two-replica NGINX **storefront** service;
- a private Redis **cart-cache** service;
- a one-shot, in-cluster **smoke-test Job** that checks storefront DNS and HTTP reachability.

It is **not a complete online-shop application**: the NGINX storefront is a deliberately small static demo and does not implement cart logic against Redis. This makes the project technically honest while still demonstrating a realistic multi-workload Kubernetes package.

## Architecture

```text
Smoke-test Job
	|
	| HTTP :8080 (allowed by NetworkPolicy)
	v
Storefront Service (ClusterIP)
	|
	v
Two storefront Pods

Cart-cache Service (ClusterIP) --> Redis Pod
```

All resources are isolated in the `storefront-demo` namespace. Both services are `ClusterIP`, so neither is publicly exposed.

## Security controls demonstrated

- Explicit CPU and memory requests/limits for every container.
- Readiness and liveness probes for long-running workloads.
- Pinned container image tags—not `latest`.
- Pod-level `RuntimeDefault` seccomp profile.
- Non-root execution, dropped Linux capabilities, and disabled privilege escalation.
- Read-only root filesystems with explicit writable `emptyDir` mounts.
- Disabled automatic ServiceAccount-token mounting because these workloads do not call the Kubernetes API.
- A NetworkPolicy that limits storefront ingress to Pods labelled as the smoke test—provided the cluster CNI enforces NetworkPolicies.
- Redis is private and uses ephemeral `emptyDir` storage, so this is appropriate only for a disposable demo.

## Repository layout

| File | Purpose |
| --- | --- |
| `kustomization.yaml` | Single entry point that assembles the namespace and every resource. |
| `namespace.yaml` | Creates the isolated `storefront-demo` namespace. |
| `config.yaml` | Provides static HTML through a ConfigMap. |
| `deployment.yaml` | Storefront and Redis Deployments with probes and pod security settings. |
| `service.yaml` | Internal DNS endpoints for the storefront and cache. |
| `network-policy.yaml` | Limits incoming storefront traffic to the smoke-test workload. |
| `smoke-test.yaml` | One-shot HTTP validation Job run inside the namespace. |

## Validate without changing a cluster

From this directory, render the full package and validate its Kubernetes schema locally:

```sh
kubectl kustomize . > /tmp/storefront-demo.yaml
kubectl apply --dry-run=client --validate=true -f /tmp/storefront-demo.yaml
```

These commands check Kustomize composition and client-side API structure. They do not create resources, pull images, test service networking, or prove that the configured cluster CNI enforces NetworkPolicies.

## Deploy and test on a non-production cluster

First verify the active kubeconfig context. Do not apply to a shared or production cluster by mistake.

```sh
kubectl config current-context
kubectl get nodes
kubectl apply -k .
kubectl rollout status deployment/storefront -n storefront-demo
kubectl rollout status deployment/cart-cache -n storefront-demo
kubectl wait --for=condition=complete job/storefront-smoke-test -n storefront-demo --timeout=120s
```

Inspect the outcome:

```sh
kubectl get deployments,pods,services,networkpolicies,jobs -n storefront-demo
kubectl logs job/storefront-smoke-test -n storefront-demo
kubectl get endpoints storefront -n storefront-demo
```

For a temporary browser check without exposing a public LoadBalancer or Ingress:

```sh
kubectl port-forward service/storefront 8080:8080 -n storefront-demo
```

Open `http://localhost:8080` while the port-forward is active.

## Production improvements

- Replace the static NGINX container with a real application that authenticates to Redis and model its configuration through Secrets/external secret management.
- Use a StatefulSet and persistent storage with backup and restore testing for any Redis data that must survive Pod rescheduling.
- Add Redis authentication, TLS where required, and a specific NetworkPolicy for each allowed client path.
- Pin reviewed image digests, scan images in CI, and use admission policies such as Pod Security Admission or Kyverno.
- Configure Horizontal Pod Autoscaling, PodDisruptionBudgets, monitoring, alerting, and a remote audit trail.
- Verify that the selected LKE/CNI configuration enforces NetworkPolicy before relying on it as a security boundary.

## Cleanup

Remove all resources created by this package:

```sh
kubectl delete -k .
```

## Verification status

The manifests are designed for non-destructive Kustomize rendering and client-side validation. A live apply, rollout, smoke test, and NetworkPolicy enforcement check require an explicit run on an accessible non-production Kubernetes cluster.