# Deploy Microservices with Helmfile

## Demo project

**Technologies:** Kubernetes, Helm, Helmfile, YAML, Docker, NGINX

This project declaratively deploys two independently versioned microservice releases—`emailservice` and `cartservice`—with Helmfile. Both releases reuse the chart in `../Create_Helm_Chart_for_Microservices`, while this directory owns their Helmfile orchestration and service-specific values.

The deployed workloads use the pinned, unprivileged NGINX image as a deliberately small HTTP demonstration. They are **not** implementations of a real cart or email business service; replacing the image and values with production workloads is the intended next step.

## Architecture

```text
helmfile.yaml
	├─ emailservice release ──┐
	└─ cartservice release ───┼─> reusable microservice Helm chart
														└─> microservice-demo namespace
```

Each release creates a `Deployment`, `ClusterIP` `Service`, readiness/liveness probes, resource requests/limits, and a Helm test hook inherited from the reusable chart.

## Repository contents

| File | Purpose |
| --- | --- |
| `helmfile.yaml` | Authoritative release inventory and safe Helm defaults. |
| `values/email-service-values.yaml` | Email release image, service, and environment values. |
| `values/cart-service-values.yaml` | Cart release image, service, and environment values. |
| `install.sh` | Guarded Helmfile synchronization wrapper. |
| `uninstall.sh` | Guarded Helmfile destroy wrapper. |

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
kubectl rollout status deployment/emailservice -n microservice-demo
kubectl rollout status deployment/cartservice -n microservice-demo
helmfile test
```

For a local HTTP check, port-forward either release:

```sh
kubectl port-forward service/emailservice 8080:8080 -n microservice-demo
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

- Replace the NGINX demo image with a reviewed application image pinned by digest.
- Store credentials in Kubernetes Secrets or an external secret manager, never in values files.
- Set service-specific requests, limits, probes, autoscaling, and NetworkPolicies based on workload measurements.
- Use a CI identity with least-privilege RBAC and protect the deployment environment with review gates.

## Verification status

The Helmfile state is rendered and validated locally with `helmfile lint`, `helmfile template`, and Kubernetes client-side dry-run validation. No cluster resources are created during those checks. A live synchronization and `helmfile test` require a reachable Kubernetes cluster and are intentionally opt-in.