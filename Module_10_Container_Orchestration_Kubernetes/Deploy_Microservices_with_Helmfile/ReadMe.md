# Deploy Microservices with Helmfile

## Demo project

**Technologies:** Kubernetes, Helm, Helmfile, YAML, Docker, NGINX

This project declaratively deploys two independently versioned releases with Helmfile: a `storefront` website and `cart-cache` Redis cache. Both releases reuse the chart in `../Create_Helm_Chart_for_Microservices`, while this directory owns their Helmfile orchestration and service-specific values.

The storefront runs the real `stefanprodan/podinfo` HTTP demo container and exposes its `/healthz` endpoint. The cache runs a real Redis container. They are **not integrated**: Podinfo does not persist business data in Redis. This is intentionally a runnable orchestration and delivery demo, not a complete online shop.

## Architecture

```text
helmfile.yaml
	├─ storefront release ───> Podinfo website :9898
	└─ cart-cache release ───> Redis cache :6379
																				└─> microservice-demo namespace
```

The storefront release creates a `Deployment`, `ClusterIP` `Service`, HTTP readiness/liveness probes, and a Helm test hook. Redis uses the same generic chart but disables HTTP-only probes and tests because Redis requires TCP or exec health checks, which are a documented next chart enhancement.

## Repository contents

| File | Purpose |
| --- | --- |
| `helmfile.yaml` | Authoritative release inventory and safe Helm defaults. |
| `values/email-service-values.yaml` | Active Podinfo storefront image, `/healthz` probe, service, and Helm HTTP test values. The inherited filename should be renamed in a future cleanup commit. |
| `values/cart-service-values.yaml` | Active Redis cache image and internal Service values, plus documented gaps for production use. The inherited filename should be renamed in a future cleanup commit. |
| `install.sh` | Guarded Helmfile synchronization wrapper. |
| `uninstall.sh` | Guarded Helmfile destroy wrapper. |

Two duplicate files—`storefront-values.yaml` and `cart-cache-values.yaml`—are marked **ARCHIVED DUPLICATE** and are not referenced by `helmfile.yaml`. They can be removed in a future Git cleanup commit.

## Delivery safeguards

The Helmfile applies these defaults to both releases:

- dedicated `microservice-demo` namespace, created when needed;
- `wait` and `waitForJobs`, so a command succeeds only after workloads become ready;
- `atomic` and `cleanupOnFail`, so failed installs roll back cleanly;
- five-minute timeout and a maximum release history of ten revisions;
- release labels for component and application grouping.

Both lifecycle scripts require an explicit confirmation variable. They will not modify or destroy cluster resources accidentally.

## Validate without a cluster

From this directory, render and validate the Helmfile state without applying resources:

```sh
helmfile lint
helmfile template > rendered-manifests.yaml
kubectl apply --dry-run=client --validate=true -f rendered-manifests.yaml
```

The local chart path means this workflow validates the chart and its release-specific values together.

## Deploy to a disposable cluster namespace

Before a real deployment, verify the current kubeconfig context:

```sh
kubectl config current-context
kubectl get nodes
```

Review changes first:

```sh
helmfile diff
```

After confirming the target is appropriate, synchronize the declared releases:

```sh
CONFIRM_DEPLOY=yes ./install.sh
```

Verify the rollout and exercise the HTTP test hooks:

```sh
kubectl get deployments,services,pods -n microservice-demo
kubectl rollout status deployment/storefront -n microservice-demo
kubectl rollout status deployment/cart-cache -n microservice-demo
helmfile test
```

For a local HTTP check, port-forward either release:

```sh
kubectl port-forward service/storefront 9898:9898 -n microservice-demo
```

## Cleanup

After reviewing the active cluster context, destroy only the releases declared in this Helmfile:

```sh
CONFIRM_DESTROY=yes ./uninstall.sh
```

The namespace remains after release destruction so that logs and troubleshooting context can be inspected. Remove it only when you are certain it contains no resources to retain:

```sh
kubectl delete namespace microservice-demo
```

## Production considerations

- Pin the reviewed website and Redis images by digest instead of mutable tags.
- Add a real cart application that connects to Redis, then add an end-to-end test that proves the data path.
- Replace the Redis Deployment with a Redis-specific StatefulSet, persistent volume, authentication, backup/restore plan, and dedicated network policy when storing non-ephemeral data.
- Store credentials in Kubernetes Secrets or an external secret manager, never in values files.
- Extend the generic chart with TCP/exec/gRPC probes and hardened pod-security values before using it for non-HTTP workloads.
- Set service-specific requests, limits, autoscaling, and NetworkPolicies based on workload measurements.
- Use a CI identity with least-privilege RBAC and protect the deployment environment with review gates.

## Verification status

The Helmfile state is rendered and validated locally with `helmfile lint`, `helmfile template`, and Kubernetes client-side dry-run validation. No cluster resources are created during those checks. A live synchronization and `helmfile test` require a reachable Kubernetes cluster and are intentionally opt-in.