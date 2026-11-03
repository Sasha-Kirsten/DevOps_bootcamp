# Continuous Deployment to Amazon EKS with Jenkins

## Demo project

**Project:** Deploy a reviewed container image to Amazon Elastic Kubernetes Service (EKS) from Jenkins.

**Technologies:** Jenkins, AWS, Amazon EKS, AWS CLI v2, Kubernetes, `kubectl`, Docker or another OCI registry, Kustomize, Git.

**Goal:** Validate Kubernetes configuration in Jenkins, authenticate to an EKS cluster with least-privilege AWS credentials, deploy an immutable image to a dedicated namespace, wait for the rollout, and collect deployment evidence.

> This directory currently documents a reference implementation. It does not contain a Jenkins server, an EKS cluster, application source, container image, or Kubernetes manifests. Do not claim a live deployment succeeded until you run the workflow against a non-production EKS cluster and record the results.

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
	├─ authenticate to AWS using a Jenkins credential
	├─ create temporary EKS kubeconfig
	├─ request deployment approval
	├─ apply manifests and set immutable image tag
	└─ wait for the Kubernetes rollout
	│
	▼
Amazon EKS cluster
	│
	▼
Dedicated application namespace
	│
	▼
Deployment, Service, Pods
```

## Why use AWS CLI instead of `aws-iam-authenticator`?

Modern EKS kubeconfig files use `aws eks get-token` through AWS CLI v2. The old `aws-iam-authenticator` workflow is not required for this reference design. Jenkins needs compatible `aws` and `kubectl` binaries on its agent; it does not need a cluster kubeconfig committed to the repository.

## Prerequisites

- An EKS cluster and a Jenkins agent with network access to its Kubernetes API endpoint.
- AWS CLI v2, `kubectl`, and Kustomize support on the Jenkins agent.
- A container registry containing a reviewed application image.
- Jenkins credentials that can assume or use an AWS identity authorized for the target cluster.
- Kubernetes RBAC granting that identity only the required access in the deployment namespace.

Validate tooling and the AWS identity before creating a pipeline:

```sh
aws --version
kubectl version --client
aws sts get-caller-identity
aws eks describe-cluster --name <cluster-name> --region <aws-region>
```

## Credential model

Store credentials in Jenkins—never in a `Jenkinsfile`, Kubernetes manifest, Git repository, build log, or `.env` file committed to source control.

| Jenkins item | Recommended type | Purpose |
| --- | --- | --- |
| `aws-eks-deployer` | AWS credential binding or an assumed-role integration | Lets Jenkins call AWS APIs and obtain an EKS authentication token. |
| `container-registry-credentials` | Username/password or cloud-native registry credential | Only needed when Jenkins publishes images. |
| `kubeconfig` | Not required for the recommended pattern | Generate a temporary kubeconfig at build time with `aws eks update-kubeconfig`. |

The AWS identity must be mapped to Kubernetes access and restricted with Kubernetes RBAC. Do not grant the Jenkins role unrestricted cluster-admin access just to make a demonstration work.

## Example Jenkinsfile

The following reference pipeline deploys only when `DEPLOY_TO_EKS` is explicitly selected. Fill in the placeholder values before use.

This example expects the Jenkins AWS Credentials plugin or an equivalent managed AWS authentication mechanism. If your Jenkins setup uses a different AWS credential plugin, adjust only the credential-binding syntax; keep the temporary kubeconfig, immutable tag, approval gate, and rollout wait behavior.

## Example Kubernetes manifests

Place these files in the directory referenced by `MANIFEST_DIRECTORY`. Replace all angle-bracket values and adapt health endpoints, ports, resource values, and security settings to the actual application.

Use a `ClusterIP` Service by default. Add an Ingress with TLS only if external HTTP access is part of the project’s documented requirements.

## Deployment and verification workflow

1. Build, test, scan, and publish an immutable application image in an upstream CI stage.
2. Select `DEPLOY_TO_EKS=true` and provide the exact `IMAGE_TAG` in Jenkins.
3. Review the manual approval prompt, then allow Jenkins to deploy.
4. Verify the workload:

```sh
kubectl get deployments,pods,services -n <application-namespace>
kubectl rollout status deployment/<application-name> -n <application-namespace>
kubectl get events -n <application-namespace> --sort-by='.lastTimestamp'
kubectl logs deployment/<application-name> -n <application-namespace>
```

For a temporary local check of an internal service:

```sh
kubectl port-forward service/<application-name> <local-port>:<service-port> -n <application-namespace>
```

## Evidence to show recruiters

Show a concise end-to-end narrative instead of exposing credentials or raw configuration files:

1. The manifest-validation stage succeeds before deployment.
2. The Jenkins build displays the immutable image tag it deploys.
3. The deployment requires opt-in and a human approval.
4. The temporary kubeconfig is generated from AWS credentials and removed after the build.
5. `kubectl rollout status` succeeds and Pods are `Ready`.
6. The deployed application returns a health response through its Service or Ingress.
7. Jenkins has least-privilege AWS and Kubernetes access rather than embedded credentials.

Capture screenshots of successful stage output, rollout state, and health response—but redact AWS account IDs, internal endpoints, tokens, kubeconfig data, and credential IDs where appropriate.

## Production-minded improvements

- Use IAM Roles for Service Accounts for application-level AWS access.
- Restrict the EKS API endpoint and Jenkins network access.
- Map the Jenkins IAM role to a namespace-scoped Kubernetes RBAC role.
- Pin image digests after image scanning instead of relying only on tags.
- Add NetworkPolicies, TLS-enabled Ingress, secret management, observability, alerting, autoscaling, and policy enforcement.
- Separate build and deployment permissions; a job that validates code should not automatically receive production cluster access.

## Verification status

The examples in this README are reference templates and have not been deployed from this directory. Before describing the project as operational, validate the actual manifests with `kubectl apply --dry-run=client --validate=true`, run the Jenkins pipeline against a non-production EKS cluster, and save redacted evidence of the successful rollout.

## References

- [Amazon EKS authentication](https://docs.aws.amazon.com/eks/latest/userguide/authenticate-iam.html)
- [AWS CLI `eks update-kubeconfig`](https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html)
- [Kubernetes deployment documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)




