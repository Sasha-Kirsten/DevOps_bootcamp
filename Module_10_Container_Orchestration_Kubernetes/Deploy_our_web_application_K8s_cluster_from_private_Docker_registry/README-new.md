# Deploy a Web Application from Private Amazon ECR

## Demo scope

**Technologies:** Amazon ECR, AWS CLI, Kubernetes, Kustomize, Docker, and Bash.

This project demonstrates the Kubernetes image-pull flow for a container stored in a **private Amazon Elastic Container Registry (ECR)** repository. It creates a short-lived Docker-registry Secret from a fresh ECR authorization token, then references that Secret with `imagePullSecrets` in an application Deployment.

It is a **deployment authentication demo**, not a complete application platform. The application image reference is deliberately a placeholder, and the generic manifest does not guess health-check paths, application configuration, or public exposure requirements. You must provide an image and application-specific settings from your own ECR repository.

## Architecture

```text
Developer or CI pipeline
        |
        | push reviewed image
        v
Private Amazon ECR repository
        |
        | fresh 12-hour ECR authorization token
        v
Kubernetes Secret: my-registry-key
        |
        | imagePullSecrets
        v
my-app Deployment --> my-app Service (ClusterIP :3000)
```

The pull Secret is used only by Kubernetes while downloading the image. It is not injected into the container as an environment variable.

## Repository layout

| File | Purpose |
| --- | --- |
| `.env` | Committed non-secret placeholders for local deployment inputs. Replace the account ID and repository for your exercise; do not add AWS access keys or tokens. |
| `create-ecr-pull-secret.sh` | Creates or refreshes `Secret/my-registry-key` from a new ECR authorization token. |
| `namespace.yaml` | Defines the isolated `private-ecr-demo` namespace. |
| `my-app-deployment.yaml` | Valid Deployment template with `imagePullSecrets`, port `3000`, resource limits, and a private-ECR placeholder image. |
| `service.yaml` | Internal `ClusterIP` service for the application. |
| `kustomization.yaml` | Renders the namespace, Deployment, and Service. It intentionally excludes the runtime-generated pull Secret. |

## What you need to supply

1. A private ECR repository containing an application image that listens on port `3000`, or an edited manifest that uses the image's real port.
2. An AWS CLI v2 identity permitted to call `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:GetDownloadUrlForLayer`, and `ecr:BatchCheckLayerAvailability` for the target repository.
3. A reachable non-production Kubernetes cluster and `kubectl` context.
4. Correct values in `.env`:
   - `AWS_REGION`—for example `eu-central-1`.
   - `AWS_ACCOUNT_ID`—your 12-digit AWS account ID.
   - `ECR_REPOSITORY`—the repository name. This is verified by the secret script so configuration is complete, but you must also replace the image value in the Deployment.
   - `NAMESPACE`—must stay `private-ecr-demo` unless you update every manifest to the same namespace.

Never place long-lived AWS credentials, ECR tokens, or Docker configuration JSON in `.env` or Git.

## Configure the image

In `my-app-deployment.yaml`, replace this placeholder:

```text
000000000000.dkr.ecr.eu-central-1.amazonaws.com/replace-me:0.0.0
```

Use a pinned tag or, preferably, an immutable digest:

```text
<account-id>.dkr.ecr.<region>.amazonaws.com/<repository>@sha256:<digest>
```

If the application does not listen on `3000`, update the named container port and Service target port together. Add readiness and liveness probes only when you know the application's real health endpoint or protocol.

## Validate without changing a cluster

Render and validate the application resources locally:

```sh
kubectl kustomize . > /tmp/private-ecr-demo.yaml
kubectl apply --dry-run=client --validate=true -f /tmp/private-ecr-demo.yaml
```

This confirms Kustomize composition and Kubernetes API structure. It cannot verify the ECR image exists, AWS permissions, token validity, or a live image pull.

## Create the ECR pull Secret

First confirm your AWS identity and review the active Kubernetes context:

```sh
aws sts get-caller-identity
kubectl config current-context
kubectl get nodes
```

Then create or refresh the ECR Secret. This action contacts AWS and writes a Secret to the configured Kubernetes namespace:

```sh
bash create-ecr-pull-secret.sh
```

ECR authorization tokens are valid for 12 hours. Refresh the Secret before it expires or automate rotation in CI/CD. Confirm only metadata; never print Secret contents:

```sh
kubectl describe secret my-registry-key -n private-ecr-demo
```

## Deploy on a disposable cluster

After replacing the image placeholder and creating the ECR pull Secret:

```sh
kubectl apply -k .
kubectl rollout status deployment/my-app -n private-ecr-demo --timeout=120s
kubectl get deployments,pods,services -n private-ecr-demo
kubectl get endpoints my-app -n private-ecr-demo
```

For a temporary workstation check, port-forward the Service:

```sh
kubectl port-forward service/my-app 3000:3000 -n private-ecr-demo
```

The application decides what URL is available on port `3000`; this generic project cannot claim a browser route without knowing the image.

## Troubleshooting

| Symptom | Likely cause and resolution |
| --- | --- |
| `ImagePullBackOff` / `ErrImagePull` | Run `kubectl describe pod <pod-name> -n private-ecr-demo`; verify the image reference, account/region, repository permissions, and fresh pull Secret. |
| `no basic auth credentials` | The Secret is missing, in a different namespace, named incorrectly, or expired. Re-run `bash create-ecr-pull-secret.sh`, then restart the Deployment. |
| AWS CLI access denied | Run `aws sts get-caller-identity` and confirm the required ECR permissions. |
| Service has no endpoints | The Pod is not Ready or its label no longer matches the Service selector. Inspect the rollout and Pod events. |
| Application is unreachable | Confirm the application listens on the declared port; `containerPort` and a Service do not create an HTTP route automatically. |

## EKS note

On Amazon EKS, the preferred operational pattern is granting the **node IAM role** the ECR read permissions. Nodes can then pull private ECR images without distributing a Docker-registry Secret. This is distinct from application-level AWS permissions, which should use workload identity such as EKS Pod Identity or IRSA.

## Portfolio improvements

- Use an immutable image digest and add an image scan gate in CI.
- Move Secret creation and ECR-token rotation into a CI/CD pipeline using a least-privilege AWS role.
- Add application-specific health probes, a PodDisruptionBudget, autoscaling, and observability only after measuring the real service.
- Use an Ingress with TLS and authentication only if the application requires external access.
- Capture redacted live evidence: successful rollout, populated Service endpoints, and the image digest in the running Pod.

## Cleanup

```sh
kubectl delete -k .
kubectl delete secret my-registry-key -n private-ecr-demo
```

Deleting these Kubernetes resources does not delete the ECR image or repository.
