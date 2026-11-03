# Schedule a Kubernetes Workload on Amazon EKS Fargate

## Demo project

**Project:** Create an EKS Fargate profile and deploy an NGINX workload selected by namespace and labels.

**Technologies:** AWS, Amazon EKS, AWS Fargate, Terraform, `eksctl`, Kubernetes, `kubectl`, YAML.

**Goal:** Demonstrate how EKS Fargate schedules Pods without managing EC2 worker nodes. The NGINX workload is selected by the `dev` namespace and `profile: fargate` label, matching the Fargate profile configuration.

> This is a sandbox infrastructure project. EKS control-plane, Fargate Pod, networking, load-balancer, and storage usage may incur AWS charges. Review the active account and region, then delete test infrastructure when finished.

## Architecture

```text
AWS account
	│
	├─ Existing or eksctl-created EKS cluster
	│     │
	│     ├─ Fargate profile: kube-system / k8s-app=kube-dns
	│     └─ Fargate profile: dev / profile=fargate
	│
	▼
Namespace: dev
	│
	▼
NGINX Deployment
	labels: app.kubernetes.io/name=nginx, profile=fargate
	│
	▼
Fargate Pod → ClusterIP Service: nginx:80
```

EKS schedules a Pod on Fargate only when it matches a Fargate profile selector. The NGINX Deployment and both provisioning approaches intentionally use the same selector:

```text
namespace: dev
label: profile=fargate
```

## Project files

| File | Purpose |
| --- | --- |
| `nginx-config.yaml` | Namespace, hardened NGINX Deployment, and internal ClusterIP Service. |
| `provision.yaml` | `eksctl` cluster configuration with CoreDNS and NGINX Fargate profile selectors. |
| `main.tf` | Terraform configuration that creates a Fargate pod-execution IAM role and Fargate profile for an **existing** EKS cluster. |
| `variables.tf`, `outputs.tf` | Terraform inputs and outputs. |
| `terraform.tfvars.example` | Safe example input values; copy it to `terraform.tfvars` locally and replace all sample values. |

### Option A — Create the cluster with `eksctl`

`provision.yaml` is appropriate when you want `eksctl` to create the cluster and its Fargate profiles:

```sh
eksctl create cluster -f provision.yaml
```

It includes a CoreDNS selector because a Fargate-only cluster needs CoreDNS to run on Fargate. Before using it, replace the `metadata.name` and `metadata.region` values with your own cluster name and approved AWS Region, then check the currently supported EKS Kubernetes versions in the AWS documentation.

## Prerequisites

- AWS CLI configured with an identity that can inspect/create EKS, IAM, and networking-related resources.
- `kubectl` and either `eksctl` or Terraform installed locally.
- An EKS cluster for the Terraform path, or permission to create one for the `eksctl` path.
- Private subnets that satisfy EKS Fargate networking requirements for the Terraform path.

Check your local tools and AWS identity before making changes:

```sh
aws sts get-caller-identity
aws --version
kubectl version --client
eksctl version
terraform version
```

## Validate safely

Validate the Kubernetes workload without connecting to a cluster:

```sh
kubectl apply --dry-run=client --validate=true -f nginx-config.yaml
```

Validate the Terraform configuration without provisioning AWS resources:

```sh
terraform fmt -check
terraform init -backend=false
terraform validate
```

For `eksctl`, review the configuration before creation:

```sh
eksctl create cluster -f provision.yaml --dry-run
```

The exact dry-run support can vary by `eksctl` version. If unavailable, review the file and use an isolated AWS sandbox account before running creation.

## Deploy and verify NGINX

After the `dev` Fargate profile is active and `kubectl` is configured for the cluster:

```sh
kubectl apply -f nginx-config.yaml
kubectl rollout status deployment/nginx -n dev
kubectl get pods,service,endpoints -n dev
```

Verify that the Pod is scheduled on Fargate:

```sh
kubectl get pod -n dev -l profile=fargate -o wide
kubectl describe pod -n dev -l profile=fargate
```

For a temporary local HTTP check of the internal service:

```sh
kubectl port-forward service/nginx 8080:80 -n dev
```

Open `http://localhost:8080` while the port-forward is active.

## Security and cost notes

- The example NGINX image is pinned and runs as non-root with a read-only root filesystem, a default seccomp profile, dropped Linux capabilities, and explicit resource settings.
- The Service is `ClusterIP`; it is not publicly exposed. Use a reviewed Ingress with TLS when external HTTP access is required.
- EKS Fargate is not a substitute for application-level IAM. Use IAM Roles for Service Accounts when a workload needs AWS permissions.
- Avoid putting secrets, kubeconfig files, account IDs, or subnet IDs into version-controlled files.
- Use a separate development account or tightly controlled sandbox. Fargate and EKS cost money while they run.

## Recruiter walkthrough

1. Start with `provision.yaml` or `main.tf` and explain why you chose that provisioning approach.
2. Show that the Fargate profile selector and NGINX Pod labels are deliberately aligned.
3. Explain that CoreDNS must also be schedulable in a Fargate-only cluster.
4. Show `nginx-config.yaml` security controls, probes, resource requests/limits, and internal Service.
5. Demonstrate a `Ready` Fargate Pod, successful rollout, and port-forwarded HTTP response.
6. Show your cleanup workflow and explain cost awareness.

## Cleanup

For the Terraform path, destroy only after confirming the target account and cluster:

```sh
terraform destroy
```

For the `eksctl` path, delete the sandbox cluster deliberately:

```sh
eksctl delete cluster --name <cluster-name> --region <aws-region>
```

Remove the demonstration workload separately when it is no longer needed:

```sh
kubectl delete -f nginx-config.yaml
```

## Verification status

The following local, non-destructive checks have passed:

- `terraform fmt -check`
- `terraform init -backend=false`
- `terraform validate`
- `kubectl apply --dry-run=client --validate=true -f nginx-config.yaml`
- Static checks confirming that the NGINX selector (`dev` plus `profile: fargate`) matches both provisioning configurations.

Terraform generated `.terraform.lock.hcl`; it is intentionally tracked so collaborators resolve the same AWS provider version. No AWS resources are created by these checks. A live EKS Fargate deployment requires an approved AWS account, suitable private subnets, and explicit execution of one provisioning path.

## References

- [Amazon EKS Fargate](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)
- [eksctl Fargate profiles](https://eksctl.io/usage/fargate/)
- [Terraform AWS EKS Fargate profile resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_fargate_profile)