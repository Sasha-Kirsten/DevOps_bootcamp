# MongoDB and Mongo Express on a Local Kubernetes Cluster

This project deploys a small two-tier application to a local Kubernetes cluster created with **Minikube**:

- **MongoDB** provides the database on port `27017`.
- **Mongo Express** provides a browser-based MongoDB administration interface on port `8081`.
- A Kubernetes **Secret** supplies credentials to containers without hard-coding them in Deployment definitions.
- A **ConfigMap** supplies the MongoDB service address to Mongo Express.

The exercise demonstrates the Kubernetes pattern of separating application workloads from configuration and sensitive values.

## Architecture

```text
Browser
	|
	| http://<Minikube-IP>:30000
	v
mongo-express Service (NodePort / port 30000)
	|
	v
Mongo Express Pod :8081
	|                 ^
	|                 |
	| ConfigMap: MongoDB service URL
	| Secret: database credentials
	v
mongodb-service :27017
	|
	v
MongoDB Pod :27017
	^
	|
Secret: root username and password
```

MongoDB is exposed only through the internal `mongodb-service`, so other pods in the cluster can reach it using `mongodb-service:27017`. Mongo Express is the only component intended to be reachable from outside the cluster.

## Manifest inventory

| File | Resources | Role in the deployment |
| --- | --- | --- |
| `secret.yaml` | `Secret/mongodb-secret` | Stores the database username and password as Base64-encoded values. |
| `config.yaml` | `ConfigMap/mongodb-configmap` | Stores the MongoDB internal service address in `database_url`. |
| `mongo.yaml` | `Deployment/mongodb-deployment`, `Service/mongodb-service` | Runs MongoDB and provides stable internal DNS on port `27017`. |
| `mongo-express.yaml` | `Deployment/mongo-express`, `Service/mongo-express` | Runs the web UI and exposes it through a `NodePort` service on port `30000`. |

## Prerequisites

- Docker Desktop (or another supported container runtime) running locally.
- Minikube.
- `kubectl`.

On macOS, install the Kubernetes tools with Homebrew:

```sh
brew install kubectl minikube
```

Start a local cluster and verify that Kubernetes is ready:

```sh
minikube start
kubectl config current-context
kubectl get nodes
```

The active context should normally be `minikube`.

## Configuration flow

Kubernetes injects values into a container through environment variables:

1. The MongoDB Deployment reads a root username and password from `mongodb-secret`.
2. The `mongodb-service` selects MongoDB pods and makes them discoverable at `mongodb-service:27017`.
3. `mongodb-configmap` stores that service address under `database_url`.
4. The Mongo Express Deployment reads the database address from the ConfigMap and credentials from the Secret, then uses them to build its MongoDB connection URL.

Secret data in YAML is Base64 **encoded**, not encrypted. Do not place real production passwords in this repository. Use a secret manager or create secrets directly in the target environment for real deployments.

## Deploy the application

Create the configuration resources before workloads that reference them:

```sh
kubectl apply -f secret.yaml
kubectl apply -f config.yaml
kubectl apply -f mongo.yaml
kubectl apply -f mongo-express.yaml
```

Confirm that the resources have been created and wait for the Pods to become ready:

```sh
kubectl get deployments,pods,services
kubectl rollout status deployment/mongodb-deployment
kubectl rollout status deployment/mongo-express
```

### Open Mongo Express

For a Minikube-native URL, run:

```sh
minikube service mongo-express --url
```

Open the returned URL in a browser. Alternatively, on a driver that exposes NodePorts directly, use the Minikube IP with port `30000`:

```sh
minikube ip
```

Then browse to `http://<minikube-ip>:30000`.

If NodePort networking is unavailable with your Minikube driver, use a port-forward instead:

```sh
kubectl port-forward service/mongo-express 8081:8081
```

Open `http://localhost:8081` while the port-forward remains running.

## Corrections required in the current YAML

The manifests demonstrate the right resource types and wiring concept, but their references must be aligned before the deployment will succeed:

1. **Secret keys do not match their references.** `secret.yaml` defines `username` and `password`, whereas `mongo.yaml` requests `monogodb-root-username` and `mongo-root-password`. Use the same keys in both places.
2. **The Mongo Express administrator username is wired to a password key.** `ME_CONFIG_MONGODB_ADMINUSERNAME` must read the username key, and a separate `ME_CONFIG_MONGODB_ADMINPASSWORD` variable should read the password key.
3. **`ConfigMapRef` is not a valid environment-value source.** Replace it with `configMapKeyRef` when reading `database_url` from `mongodb-configmap`.
4. **The Mongo Express Service selector is incorrect.** It selects `app: mongodb-express`, while the Mongo Express Pod label is `app: mongo-express`; the selector must match the Pod label or the service will have no endpoints.
5. **Review the MongoDB connection URI.** After correcting the environment variable names, use the username and password values once each and point to `mongodb-service:27017`.
6. **Pin image versions** rather than relying on the untagged `mongo` and `mongo-express` images, which can change unexpectedly.

After making a manifest change, reapply that file and check the workload logs:

```sh
kubectl apply -f mongo.yaml
kubectl apply -f mongo-express.yaml
kubectl logs deployment/mongodb-deployment
kubectl logs deployment/mongo-express
```

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Pod is in `CreateContainerConfigError` | Verify the referenced Secret/ConfigMap names and keys exist: `kubectl describe pod <pod-name>`. |
| Mongo Express loads but cannot connect | Confirm that `mongodb-service` has endpoints and validate the connection URL and credentials. |
| Service has no endpoints | Compare the Service `spec.selector` labels with the pod-template labels. |
| Browser cannot reach the UI | Use `minikube service mongo-express --url` or the port-forward fallback. |
| Image cannot be pulled | Confirm Docker is running and use a valid, pinned image tag. |

## Cleanup

Remove the resources when you finish the exercise:

```sh
kubectl delete -f mongo-express.yaml
kubectl delete -f mongo.yaml
kubectl delete -f config.yaml
kubectl delete -f secret.yaml
minikube stop
```

Use `minikube delete` instead of `minikube stop` only when you want to remove the whole local cluster and all data stored in it.


