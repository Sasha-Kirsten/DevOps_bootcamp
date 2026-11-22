# Continuous Deployment to Linode Kubernetes Engine with Jenkins

## Demo project

**Project:** Deploy a reviewed container image to Linode Kubernetes Engine (LKE) through a Jenkins pipeline.

**Technologies:** Jenkins, Kubernetes, Linode Kubernetes Engine, `kubectl`, Kustomize, Docker or another OCI registry, Git.

**Goal:** Validate Kubernetes manifests in Jenkins, authenticate with a securely stored LKE kubeconfig, deploy an immutable image to a dedicated namespace, wait for the rollout, and capture deployment evidence.

> This repository is a **completion template**. The `Jenkinsfile` and resources under `k8s/` contain empty fields that you must replace with values for your own application and LKE cluster. Do not claim a live deployment has succeeded until you have tested it against a non-production LKE cluster.

## Architecture

```text
Developer push
  │
  ▼
Git repository
  │
  ▼
Jenkins pipeline
  ├─ validate Kustomize manifests
  ├─ select an immutable image tag
  ├─ load LKE kubeconfig from Jenkins credentials
  ├─ request a manual deployment approval
  ├─ apply the Kustomize package
  └─ wait for the rollout and list workload status
  │
  ▼
Linode Kubernetes Engine cluster
  │
  ▼
Dedicated namespace → Deployment → Service → Pods
```

## Repository contents

| Path | Purpose | Status |
| --- | --- | --- |
| `Jenkinsfile` | Validates manifests, then optionally deploys through a Jenkins-stored kubeconfig. | Fill in the empty parameters and environment values. |
| `k8s/namespace.yaml` | Defines the target namespace. | Replace empty `name` and project label. |
| `k8s/deployment.yaml` | Defines the application workload, probes, resources, and pod security controls. | Replace every empty value with application-specific settings. |
| `k8s/service.yaml` | Creates an internal `ClusterIP` service. | Replace empty name, namespace, labels, and port. |
| `k8s/kustomization.yaml` | Groups the Kubernetes resources for `kubectl kustomize` and `kubectl apply -k`. | Resource list is ready; add a namespace only after choosing one. |

## What you need to fill in

### Jenkins pipeline

Complete the empty parameter declarations in `Jenkinsfile` with these values:

| Value | Meaning | Example format |
| --- | --- | --- |
| `IMAGE_TAG` | Immutable container tag selected for deployment. | `1.2.3-ci.42` |
| `DEPLOY_TO_LKE` | Boolean flag; keep `false` by default. | `false` |
| `KUBECONFIG_CREDENTIAL_ID` | Jenkins **Secret file** credential ID that stores the LKE kubeconfig. | `lke-kubeconfig` |
| `KUBERNETES_NAMESPACE` | Namespace created by `namespace.yaml`. | `portfolio-demo` |
| `APPLICATION_NAME` | Deployment name and container name. | `web-demo` |
| `MANIFEST_DIRECTORY` | Folder containing `kustomization.yaml`. | `k8s` |
| `IMAGE_REPOSITORY` | Registry repository without a tag. | `registry.example.com/team/web-demo` |

The Jenkins agent needs `kubectl` with Kustomize support. It does **not** need AWS CLI or `aws-iam-authenticator`; those tools are unrelated to an LKE kubeconfig-based deployment.

### Kubernetes manifests

Use the **same application name** consistently in all of these fields:

- `metadata.name` in `deployment.yaml` and `service.yaml`;
- `containers[].name` in `deployment.yaml`;
- `app.kubernetes.io/name` labels and selectors;
- Jenkins `APPLICATION_NAME`.

Replace every empty value in `k8s/` before validation:

| Field | What to provide |
| --- | --- |
| Namespace name | A dedicated non-production namespace, for example `portfolio-demo`. |
| Project label | A short project grouping label. |
| Image | A reviewed image with an immutable tag or digest. Do not use `latest`. |
| Replicas | At least `1` for the demo; use `2` if showing availability behavior. |
| Container and Service ports | The real HTTP port your app listens on. |
| Probe path | A real health endpoint, for example `/health`. |
| Probe timings | Values based on application start-up behavior. |
| CPU and memory values | Conservative requests/limits based on measurements or documented assumptions. |

If the container uses `readOnlyRootFilesystem: true`, verify that the application does not need to write to its root filesystem. Add `emptyDir` mounts for required temporary paths instead of removing the security control without explanation.

## Jenkins credential and RBAC setup

1. Download an LKE kubeconfig with restricted, non-production access.
2. In Jenkins, create a **Secret file** credential containing that kubeconfig.
3. Give it the same credential ID used by `KUBECONFIG_CREDENTIAL_ID`.
4. Ensure the Kubernetes identity has only the required namespace-scoped permissions: typically `get`, `list`, `watch`, `create`, `patch`, and `update` for the workload resources your pipeline manages.

Never commit kubeconfig files, Linode API tokens, registry passwords, or credentials to this repository. Do not copy a kubeconfig into the Jenkins container filesystem manually; Jenkins credential binding makes the file available only during the relevant pipeline step.

## Validate before deployment

After replacing the empty values, validate the manifest package locally without changing a cluster:

```sh
cd k8s
kubectl kustomize . > rendered-manifests.yaml
kubectl apply --dry-run=client --validate=true -f rendered-manifests.yaml
```

The validation stage in `Jenkinsfile` performs the same checks. It should pass before the pipeline presents any deployment approval.

## Deployment workflow

1. Build, test, scan, and publish an immutable application image in an upstream CI job.
2. Run the Jenkins pipeline with `DEPLOY_TO_LKE=false` to validate manifests only.
3. Review the rendered resources and the selected image tag.
4. Re-run with `DEPLOY_TO_LKE=true` and a populated `IMAGE_TAG`.
5. Review the manual approval prompt before allowing deployment.
6. Jenkins applies the Kustomize package, updates the Deployment image, waits for rollout completion, and lists the resulting resources.

After a deployment, verify the cluster state independently:

```sh
kubectl get deployments,pods,services -n <namespace>
kubectl rollout status deployment/<application-name> -n <namespace>
kubectl get events -n <namespace> --sort-by='.lastTimestamp'
kubectl logs deployment/<application-name> -n <namespace>
```

For an internal `ClusterIP` service, use a temporary port-forward to check the application endpoint:

```sh
kubectl port-forward service/<application-name> <local-port>:<service-port> -n <namespace>
```

## Production-minded improvements

- Use separate development, staging, and production namespaces/clusters with approval controls appropriate to each environment.
- Enforce least-privilege Kubernetes RBAC for the Jenkins identity.
- Pin reviewed image digests after vulnerability scanning.
- Use an external secret-management solution for application secrets.
- Add NetworkPolicies, TLS-enabled Ingress, autoscaling, monitoring, alerting, and backup/recovery procedures as appropriate.
- Keep build and deployment credentials separate.

## Verification status

The current Kubernetes and Jenkins files are templates with intentionally empty values, so they are not yet renderable or deployable. Complete the values above, run the local Kustomize validation, then test the Jenkins pipeline against a non-production LKE cluster before presenting it as an operational CD implementation.

## References

- [Linode Kubernetes Engine documentation](https://www.linode.com/docs/products/compute/kubernetes/)
- [Jenkins credentials binding](https://www.jenkins.io/doc/pipeline/steps/credentials-binding/)
- [Kubernetes Deployment documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Kustomize documentation](https://kubectl.docs.kubernetes.io/references/kustomize/)