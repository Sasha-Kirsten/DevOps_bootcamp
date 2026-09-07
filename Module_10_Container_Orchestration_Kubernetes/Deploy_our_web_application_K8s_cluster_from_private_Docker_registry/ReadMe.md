# Deploy a Web Application from Private Amazon ECR

This project demonstrates how a Kubernetes cluster pulls a container image from a **private Amazon Elastic Container Registry (ECR)** repository.

Public images can be pulled by any cluster node. A private ECR repository requires authentication first. This demo supplies that authentication to Kubernetes as a Docker-registry Secret, then references the Secret from the application Pod specification through `imagePullSecrets`.

## Architecture

```text
Developer / CI pipeline
	|
	| Push image
	v
Amazon ECR private repository
	|
	| Authenticated image pull
	v
Kubernetes node (Minikube or managed cluster)
	|
	| imagePullSecrets: my-registry-key
	v
my-app Deployment
	|
	v
my-app Pod :3000
```

The registry Secret is used only while Kubernetes pulls the image. It is not automatically available as an environment variable inside the application container.

## Files in this directory

| File | Intended resource | Purpose |
| --- | --- | --- |
| `docker-secret.yaml` | `Secret/my-registry-key` | Holds Docker client configuration in the `.dockerconfigjson` key for ECR authentication. |
| `my-app-deployment.yaml` | `Deployment/my-app` | Runs one application Pod from the private ECR image and exposes container port `3000` inside the Pod. |

> **Note:** The current files are a learning scaffold and need the corrections listed below before applying them.

## Prerequisites

- An AWS account and a private ECR repository containing the application image.
- AWS CLI v2 configured with credentials that may call `ecr:GetAuthorizationToken`. The identity also needs permission to pull repository layers, including `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, and `ecr:BatchCheckLayerAvailability`.
- `kubectl` connected to the target Kubernetes cluster.
- Docker installed locally if you want to test the image pull before deployment.
- For a local setup: Minikube and a running container runtime.

The registry hostname format is:

```text
<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com
```

For example, use `eu-central-1`—not `eu-central`—for the Frankfurt region.

## Authentication flow

ECR does not use a permanent Docker password. The AWS CLI generates an authorization token, which is valid for **12 hours**. A Docker login converts that token into Docker configuration, and Kubernetes stores that configuration in a Secret of type `kubernetes.io/dockerconfigjson`.

First define values for your account, region, repository, and namespace:

```sh
export AWS_REGION=eu-central-1
export AWS_ACCOUNT_ID=<your-12-digit-account-id>
export ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export ECR_REPOSITORY=<repository-name>
export IMAGE_TAG=<image-tag>
export NAMESPACE=default
```

Verify that your identity can request an ECR token and optionally test the image locally:

```sh
aws sts get-caller-identity
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker pull "${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
```

## Create the Kubernetes pull secret

Create the Secret directly from the fresh ECR token. This avoids committing an expiring credential or a generated Docker configuration file to Git:

```sh
kubectl create secret docker-registry my-registry-key \
	--namespace "$NAMESPACE" \
	--docker-server="$ECR_REGISTRY" \
	--docker-username=AWS \
	--docker-password="$(aws ecr get-login-password --region "$AWS_REGION")" \
	--dry-run=client -o yaml | kubectl apply -f -
```

Confirm only the Secret metadata and type—do **not** copy its encoded data into tickets, logs, or source control:

```sh
kubectl get secret my-registry-key --namespace "$NAMESPACE"
kubectl describe secret my-registry-key --namespace "$NAMESPACE"
```

The Secret and the Pod must be in the **same namespace**. Re-create or rotate this Secret before the ECR token expires, and automate rotation in a real environment.

## Configure and deploy the application

Before applying `my-app-deployment.yaml`, replace the placeholder image with your complete image reference:

```text
<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com/<repository-name>:<image-tag>
```

Then add the pull-secret reference under `spec.template.spec`:

```yaml
imagePullSecrets:
	- name: my-registry-key
```

Apply the corrected Deployment and monitor the rollout:

```sh
kubectl apply -f my-app-deployment.yaml --namespace "$NAMESPACE"
kubectl rollout status deployment/my-app --namespace "$NAMESPACE"
kubectl get pods --namespace "$NAMESPACE"
```

This project currently creates a Deployment only. A `containerPort` documents the port used by the application; it does **not** expose the application outside the Pod. Add a Kubernetes Service—and optionally an Ingress—if the application needs to be reachable by other workloads or a browser.

For a temporary local test without adding a Service, forward port `3000` from the Deployment:

```sh
kubectl port-forward deployment/my-app 3000:3000 --namespace "$NAMESPACE"
```

## Corrections required in the current YAML

1. **Do not use `cat docker/config.json` as a YAML value.** The `.dockerconfigjson` field must contain Base64-encoded Docker config JSON. Prefer creating the Secret with `kubectl create secret docker-registry` as shown above, rather than committing it to `docker-secret.yaml`.
2. **Use `imagePullSecrets`, not `imagePullPolicy`, for the registry Secret.** In `my-app-deployment.yaml`, replace the invalid top-level `imagePullPolicy` list under `spec.template.spec` with:

	 ```yaml
	 imagePullSecrets:
		 - name: my-registry-key
	 ```

	 `imagePullPolicy: Always` belongs in the individual container definition, where it already appears.
3. **Replace the placeholder image.** `XXXXX.dkr.ecr.eu-central-1.amazonaws.com/XXXX` is not a valid deployable image reference. Add the repository name and a pinned image tag.
4. **Use the correct AWS region identifier.** The login command must use `--region eu-central-1` for the registry hostname in this example.

## Troubleshooting

| Symptom | Likely cause and resolution |
| --- | --- |
| `ImagePullBackOff` or `ErrImagePull` | Inspect `kubectl describe pod <pod-name>`. Confirm the image exists, the registry hostname matches the image, and `my-registry-key` exists in the Pod namespace. |
| `no basic auth credentials` | The Pod is not referencing `imagePullSecrets`, the Secret name is wrong, or the ECR token is expired. Re-create the Secret and restart the Deployment. |
| AWS CLI access denied | Verify the AWS identity and ECR pull permissions with `aws sts get-caller-identity`. |
| Image works locally but not in Minikube | The Minikube node still needs Kubernetes to receive a valid registry Secret; a host-level Docker login alone is not a durable cluster configuration. |
| Application starts but is unreachable | Add a Service or use port-forwarding; `containerPort` alone does not publish network access. |

Useful diagnostics:

```sh
kubectl get events --namespace "$NAMESPACE" --sort-by='.lastTimestamp'
kubectl describe deployment my-app --namespace "$NAMESPACE"
kubectl logs deployment/my-app --namespace "$NAMESPACE"
```

## EKS note

When deploying to Amazon EKS, a more secure operational model is to give the worker-node IAM role permission to pull from ECR. In that case, nodes can obtain ECR authorization without distributing a static image-pull Secret. Workload identity is still recommended for application-level AWS access, but it is separate from the node’s ability to pull the image.

## Cleanup

Remove the application and its registry credentials when the exercise is complete:

```sh
kubectl delete deployment my-app --namespace "$NAMESPACE"
kubectl delete secret my-registry-key --namespace "$NAMESPACE"
```

Deleting the Kubernetes resources does not delete the ECR image or repository from AWS.