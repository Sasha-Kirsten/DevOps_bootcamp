# Deploying a MongoDB Microservices Demo with Helm

This exercise explores how **Helm** can package and configure a small Kubernetes application made up of two cooperating services:

- **MongoDB** is the stateful database. It stores the application data and requires persistent storage.
- **Mongo Express** is a web administration UI. It connects to MongoDB with the database administrator credentials.
- **NGINX Ingress** exposes the Mongo Express web UI through a hostname instead of a direct service port.

The intended outcome is a reusable Helm chart: common `Deployment` and `Service` boilerplate should live in shared templates, while each component supplies only its own image, ports, environment variables, and configuration values.

## Architecture

```text
Browser
	|
	| http(s)://<host>/
	v
NGINX Ingress Controller
	|
	v
mongo-express-service :8081
	|
	v
Mongo Express Pod :8081
	|
	| MongoDB connection URL + administrator credentials
	v
MongoDB Service
	|
	v
MongoDB Stateful workload + persistent volume
```

Only Mongo Express needs external HTTP routing. MongoDB should remain an internal cluster service; exposing a database directly through an Ingress is both unnecessary and unsafe.

## Files in this directory

| File | Purpose | Notes |
| --- | --- | --- |
| `helm-mongodb.yaml` | MongoDB Helm values override. | Requests replica-style architecture, three replicas, a Linode storage class, and a root password. It is **not** a Kubernetes resource manifest by itself. |
| `helm-mongo-express.yaml` | Mongo Express `Deployment` and `Service`. | Defines the web UI image, port `8081`, and MongoDB credential environment variables. This should ultimately become a Helm template. |
| `helm-ingress.yaml` | Ingress for the Mongo Express service. | Routes `/` on a chosen host to `mongo-express-service:8081`. |
| `test-kubeconfig.yaml` | Kubeconfig structure/template. | Holds cluster, user, context, and token fields. It is not an application manifest and must never be committed with live credentials. |

## Helm concepts demonstrated

Helm separates the reusable application definition from environment-specific settings:

- **Chart templates** generate Kubernetes resources such as Deployments, Services, Secrets, and Ingresses.
- **Values files** provide settings for a particular environment—for example replica count, storage class, hostname, or image tag.
- A **release** is an installed instance of a chart. The same chart can be installed separately in development, staging, and production with different values.

For a finished shared chart, a sensible layout would be:

```text
mongo-demo/
	Chart.yaml
	values.yaml
	templates/
		_helpers.tpl
		deployment.yaml
		service.yaml
		ingress.yaml
		secret.yaml
```

The `Deployment` and `Service` templates can be parameterized with a component name, container image, container port, service port, labels, and environment variables. This avoids duplicating standard Kubernetes metadata, selectors, and service definitions for every microservice.

## Prerequisites

Before deploying, ensure that you have:

- A working Kubernetes cluster and a valid current kubeconfig context.
- `kubectl` and Helm 3 installed.
- An NGINX Ingress controller installed if you plan to use `helm-ingress.yaml`.
- A storage class named `linode-block-storage`, or a replacement storage class appropriate for your cluster.
- A DNS record (or local hosts-file entry for testing) matching the Ingress host.

Confirm the selected cluster before changing anything:

```sh
kubectl config current-context
kubectl get nodes
kubectl get storageclass
```

## Deployment workflow

1. **Create an isolated namespace.** Keeping the demo separate makes resources and cleanup easier to manage.
2. **Install MongoDB from a Helm chart** using a reviewed values file. Use a Kubernetes Secret or a Helm secret-management solution for the database password rather than storing it as plaintext in source control.
3. **Deploy Mongo Express.** Its connection URL must point to the MongoDB Service name created by the database release, and its password reference must use the actual Secret name and key created by that chart.
4. **Apply the Ingress** after setting a real `metadata.name` and `spec.rules[].host` value.
5. **Verify the rollout** before opening the UI.

Useful verification commands are:

```sh
kubectl get pods,services,ingress -n <namespace>
kubectl rollout status deployment/mongo-express -n <namespace>
kubectl logs deployment/mongo-express -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
```

For a temporary local check without DNS or Ingress, port-forward the service and open `http://localhost:8081`:

```sh
kubectl port-forward service/mongo-express-service 8081:8081 -n <namespace>
```

## Important configuration gaps to resolve

These files are a learning scaffold and require the following corrections before they can be applied successfully:

1. `helm-mongodb.yaml` contains a plaintext sample password. Replace it with a secure, externally supplied value and do not commit real secrets.
2. The key `persistance` is misspelled. The exact persistence key also depends on the MongoDB chart version, so check that chart's `values.yaml` before installing.
3. `helm-mongo-express.yaml` has a label mismatch: the Deployment selector uses `app: mongo-express`, but the pod template says `app: monog-express`. Kubernetes requires those labels to match.
4. `ME_CONFIG_MONGODB_URL` is blank. Set it to the MongoDB service endpoint expected by the selected MongoDB chart.
5. The Mongo Express manifest assumes a Secret named `mongodb` with a `mongodb-root-password` key. Confirm the installed chart actually creates that name and key, or parameterize both values in the Helm chart.
6. `helm-ingress.yaml` has an empty resource name and the placeholder host `XXX`; both must be set. The ingress class must also match the controller installed in the cluster.
7. The YAML indentation under the Mongo Express Service selector should be corrected so `app: mongo-express` is nested under `selector`.
8. `test-kubeconfig.yaml` is a template only. Populate it through a trusted provider workflow, restrict its file permissions, and keep tokens out of Git.

## Production-minded improvements

To evolve this demo beyond the exercise, add the following to the chart:

- Resource requests and limits for both containers.
- Liveness and readiness probes, especially for the Mongo Express HTTP endpoint.
- A dedicated non-root database user for the UI instead of the MongoDB root user.
- TLS on the Ingress, with certificate management such as cert-manager.
- NetworkPolicies that permit MongoDB traffic only from approved workloads.
- Persistent-volume sizing, backup/restore procedures, and a tested recovery plan.
- Pinned container image versions instead of the untagged `mongo-express` image.

## Cleanup

Remove the Helm release and namespace once you have finished experimenting:

```sh
helm uninstall <mongodb-release> -n <namespace>
kubectl delete namespace <namespace>
```

Deleting a release or namespace does not always delete the underlying persistent volume. Inspect persistent-volume claims deliberately if you need to retain or permanently remove database data.