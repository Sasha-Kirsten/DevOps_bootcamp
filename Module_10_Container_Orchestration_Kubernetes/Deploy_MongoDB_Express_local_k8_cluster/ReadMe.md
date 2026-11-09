# MongoDB and Mongo Express on Local Kubernetes

## Demo project

**Technologies:** Kubernetes, Minikube, Kustomize, MongoDB, Mongo Express, Docker

This project deploys a small, namespace-isolated MongoDB stack for local Kubernetes practice. MongoDB remains reachable only within the cluster; Mongo Express is exposed through a local `NodePort` for browser access.

It is a **local development demonstration**, not a production database platform. The included credentials are deliberately non-sensitive local examples and must be replaced through an external secret workflow in any shared or production environment.

## Architecture

```text
Browser
  │ http://<minikube-ip>:30000
  ▼
mongo-express Service (NodePort)
  ▼
Mongo Express Pod :8081
  │  ▲ Secret credentials + ConfigMap service address
  ▼
mongodb-service :27017 (ClusterIP)
  ▼
MongoDB Pod + PersistentVolumeClaim
```

All application resources are deployed to the `mongo-demo` namespace. The MongoDB Service is `ClusterIP`, so it is never directly exposed outside the cluster.

## What is included

| File | Role |
| --- | --- |
| `kustomization.yaml` | Single deployment entry point; applies every resource in the correct namespace. |
| `namespace.yaml` | Creates the isolated `mongo-demo` namespace. |
| `secret.yaml` | Local-only MongoDB root credentials using `stringData`. |
| `config.yaml` | Provides the internal MongoDB DNS address to Mongo Express. |
| `mongo.yaml` | MongoDB PVC, Deployment, and internal ClusterIP Service. |
| `mongo-express.yaml` | Mongo Express Deployment and externally reachable NodePort Service. |

Both container images are pinned, deployments have resource requests/limits, and readiness/liveness probes identify unavailable workloads.

## Prerequisites

- Minikube with a working container runtime.
- `kubectl`.
- A Minikube storage provisioner (enabled by default in a typical Minikube installation) to satisfy the `1Gi` PVC.

Start and inspect the local cluster before any deployment:

```sh
minikube start
kubectl config current-context
kubectl get nodes
kubectl get storageclass
```

The selected context should be your intended local cluster, commonly `minikube`.

## Validate without changing a cluster

Render the Kustomize resources and run Kubernetes client-side validation:

```sh
kubectl kustomize . > rendered-manifests.yaml
kubectl apply --dry-run=client --validate=true -f rendered-manifests.yaml
```

This detects structural/API-schema errors but does not pull images, provision storage, or create cluster resources.

## Deploy and verify

After confirming the current context is safe, apply the entire stack:

```sh
kubectl apply -k .
kubectl rollout status deployment/mongodb -n mongo-demo
kubectl rollout status deployment/mongo-express -n mongo-demo
kubectl get pods,services,pvc -n mongo-demo
```

Obtain a Minikube URL for Mongo Express:

```sh
minikube service mongo-express --namespace mongo-demo --url
```

Alternatively, use a port-forward that does not depend on NodePort routing:

```sh
kubectl port-forward service/mongo-express 8081:8081 -n mongo-demo
```

Open `http://localhost:8081` while the port-forward remains active. Mongo Express uses the distinct `express_username` and `express_password` local demo values in `secret.yaml` for browser basic authentication; do not reuse them elsewhere.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| PVC remains `Pending` | Verify a default StorageClass and Minikube storage provisioner: `kubectl get storageclass`. |
| Mongo Express cannot connect | Confirm both rollouts completed and inspect `kubectl logs deployment/mongo-express -n mongo-demo`. |
| Service has no endpoints | Compare the Service selector with the pod labels using `kubectl get endpoints -n mongo-demo`. |
| Browser cannot reach NodePort | Use the documented port-forward fallback. |
| Pod cannot start | Inspect events with `kubectl describe pod <pod> -n mongo-demo`. |

## Production considerations

- Do not commit credentials; use an external secret manager or sealed/encrypted secret workflow.
- Pin images by digest after security review rather than only by tag.
- Use a StatefulSet, backups, tested restoration, authentication/authorization policies, TLS, NetworkPolicies, and monitoring for a production MongoDB deployment.
- Expose administrative interfaces only through authenticated, encrypted access paths—not a public NodePort.

## Verification status

The following non-destructive checks have passed:

- `kubectl kustomize .`
- `kubectl apply --dry-run=client --validate=true -f <rendered-manifests>`

The validation rendered and client-side validated the Namespace, ConfigMap, Secret, two Services, PersistentVolumeClaim, and both Deployments. It does not prove that images can be pulled, the PVC can bind, MongoDB accepts the supplied credentials, or Mongo Express can reach MongoDB.

Before presenting a live demonstration, run the deployment workflow on a disposable Minikube cluster and capture redacted evidence of:

1. Both Deployments completing their rollouts.
2. A Bound `mongodb-data` PVC.
3. Ready Pods and populated Service endpoints.
4. A successful Mongo Express browser login through port-forward or the Minikube Service URL.
5. A Mongo Express connection to the `mongodb-service` database endpoint.

## Cleanup

Remove the whole demo and its PVC:

```sh
kubectl delete -k .
```

Confirm the PVC removal deliberately if you changed the storage-retention behavior or stored data you intend to preserve.


