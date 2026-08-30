# Automate Kubernetes Deployment

## Overview

This project demonstrates how Terraform and Ansible can automate a Kubernetes deployment on Amazon Elastic Kubernetes Service (EKS).

Terraform is responsible for provisioning the AWS infrastructure, including the EKS cluster and its worker nodes. After the cluster is available, Ansible connects to the Kubernetes API and deploys an application into a dedicated Kubernetes namespace.

```text
Terraform plan and apply
		  │
		  ▼
AWS EKS cluster and worker nodes
		  │
		  ▼
AWS CLI creates or updates kubeconfig
		  │
		  ▼
Ansible connects to the Kubernetes API
		  │
		  ▼
Namespace, Deployment, Service, and application resources
```

> **Learning project:** The current Terraform and Ansible files are starter examples. Review the **Before You Run** checklist before running them against AWS.

## Project Files

| File | Purpose |
| --- | --- |
| `eks-cluster.tf` | Intended Terraform definition for the EKS cluster and managed node group configuration. |
| `main.tf` | Intended location for provider configuration, VPC/network resources, Terraform versions, outputs, and supporting EKS resources. It is currently empty. |
| `deploy-kuberenetes.yaml` | Intended Ansible playbook that deploys an application to the EKS cluster. It is currently empty. |
| `ansible.cfg` | Ansible defaults. It currently contains EC2 SSH inventory settings, which are not the primary connection method for Kubernetes resource deployment. |
| `ReadMe.md` | Explains the intended infrastructure and application deployment workflow. |

## Key Terms

| Term | Meaning |
| --- | --- |
| **EKS** | AWS-managed Kubernetes control plane service. |
| **Control plane** | Kubernetes API and core management components operated by AWS in EKS. |
| **Managed node group** | EC2 worker nodes created and maintained by EKS to run application Pods. |
| **Kubeconfig** | A local configuration file that tells `kubectl` and Ansible how to authenticate to a Kubernetes cluster. |
| **Namespace** | A logical Kubernetes partition that separates application resources, such as development and production workloads. |
| **Deployment** | A Kubernetes resource that maintains the requested number of application Pods. |
| **Service** | A stable network endpoint for reaching a set of Pods. |

## Prerequisites

Before starting, prepare the following:

- An AWS account and an IAM identity authorised to create EKS, IAM, VPC, EC2, and related resources for a learning environment.
- Terraform installed and authenticated to AWS through an IAM role, AWS profile, or another approved credential method.
- AWS CLI installed and authenticated to the same AWS account and Region.
- `kubectl` installed to inspect the cluster and application resources.
- Ansible installed with the Kubernetes collection and its Python dependencies, including the Kubernetes Python client.
- A container image for the application, published to a registry that EKS nodes can access.
- A VPC with private or public subnets in at least two Availability Zones for a resilient EKS setup.
- A clear application namespace, image tag, container port, and service exposure method.

Verify the locally installed tools:

```bash
terraform version
aws --version
kubectl version --client
ansible --version
ansible-galaxy collection list kubernetes.core
```

> **Security note:** Do not store AWS access keys, kubeconfig files, registry passwords, or Kubernetes secrets in Git. Use IAM roles, a CI/CD credential store, Kubernetes Secrets, or another approved secret-management system.

## Implementation Steps

### 1. Define the AWS provider and Terraform versions

Add the Terraform and AWS provider configuration in `main.tf` or a dedicated `versions.tf` and `provider.tf`. Pin tested versions so a provider upgrade does not unexpectedly change the cluster configuration.

Use secure AWS authentication. Do not hard-code `access_key` or `secret_key` values in Terraform files.

### 2. Create the EKS network and IAM prerequisites

An EKS cluster requires more than the cluster resource alone. Define or reference:

- A VPC and subnets in at least two Availability Zones.
- Route tables, internet or NAT access, and required security groups.
- An EKS cluster IAM role.
- Node IAM role and policies for managed worker nodes.
- Cluster and node security-group rules.
- Tags required for Kubernetes load balancers or AWS integrations when applicable.

For team-based work, store Terraform state in an encrypted, versioned remote backend with locking. Keep separate state files for development, test, staging, and production environments.

### 3. Create the EKS cluster and managed nodes

Configure the EKS cluster name, Kubernetes version, subnets, endpoint access, logging, encryption, and tags. Create managed node groups that define the EC2 AMI type, instance type, and desired scaling range.

For a production cluster, prefer private endpoint access or restrict public endpoint access to trusted CIDR ranges. Deploy workloads on at least two Availability Zones and set realistic minimum, maximum, and desired node counts.

### 4. Validate and apply the Terraform configuration

Run Terraform checks before creating AWS resources:

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan -out=tfplan
```

Review the plan carefully, especially IAM, security-group, network, and resource-deletion changes. Apply the reviewed plan only after approval:

```bash
terraform apply tfplan
```

EKS creation may take several minutes. Terraform outputs should provide the cluster name, AWS Region, and other connection details required for deployment.

### 5. Configure access to the EKS cluster

After Terraform creates the cluster, use the AWS CLI to update the local kubeconfig:

```bash
aws eks update-kubeconfig --region <aws-region> --name <cluster-name>
kubectl get nodes
```

The `kubectl get nodes` command should show nodes in the `Ready` state before deploying an application. The IAM identity used by the AWS CLI and Ansible must have Kubernetes access through EKS access entries or another approved authentication and authorisation configuration.

### 6. Write the Ansible Kubernetes playbook

Add deployment tasks to `deploy-kuberenetes.yaml`. For Kubernetes deployments, Ansible normally uses the `kubernetes.core.k8s` module and connects through the local kubeconfig rather than SSHing to worker nodes.

The playbook should declare the desired Kubernetes resources, such as:

1. A namespace for the application.
2. A Kubernetes Secret or reference to an external secret-management system.
3. A Deployment with the selected versioned container image.
4. A Service that exposes the application internally or externally.
5. Optional Ingress, ConfigMap, resource limits, readiness probes, and network policies.

Use a dedicated namespace, for example `myapp-dev`, rather than deploying application workloads into the `default` namespace.

### 7. Apply and verify the Ansible deployment

First validate the playbook syntax, then apply it using the kubeconfig for the EKS cluster:

```bash
ansible-playbook --syntax-check deploy-kuberenetes.yaml
ansible-playbook deploy-kuberenetes.yaml
```

Use `kubectl` to confirm the namespace, Pods, Deployment, and Service are healthy:

```bash
kubectl get namespace
kubectl get deployment,pods,services -n <namespace>
kubectl rollout status deployment/<deployment-name> -n <namespace>
```

### 8. Clean up unused learning resources

EKS, worker nodes, NAT gateways, and load balancers can incur ongoing AWS charges. Delete learning resources after use only when they are no longer required:

```bash
terraform destroy
```

Review the destroy plan before confirming it. Do not destroy a shared or production cluster without formal approval and backups.

## Before You Run

Complete these corrections and decisions before using the current files:

- [ ] Add Terraform provider, version, remote-state backend, networking, IAM roles, variables, and outputs; `main.tf` is currently empty.
- [ ] Correct the native `aws_eks_cluster` resource in `eks-cluster.tf`. Attributes such as `subnet_ids`, `vpc_id`, `endpoint_public_access`, and `eks_managed_node_groups` are module-style settings and are not configured directly on the native resource in that form.
- [ ] Define an EKS cluster IAM role and node IAM role before creating the cluster and worker nodes.
- [ ] Use at least two eligible subnets in separate Availability Zones, rather than only one `var.subnet_id`.
- [ ] Choose and configure a valid managed-node resource or a supported, pinned EKS Terraform module.
- [ ] Restrict `endpoint_public_access`; do not leave the Kubernetes API public to all internet addresses in a real environment.
- [ ] Add tasks to `deploy-kuberenetes.yaml`; it is currently empty. Consider renaming it to `deploy-kubernetes.yaml` to correct the filename.
- [ ] Install and configure the `kubernetes.core` Ansible collection and Kubernetes Python client before using Kubernetes modules.
- [ ] Update or remove the SSH-specific settings in `ansible.cfg` for this Kubernetes deployment workflow. The playbook should use kubeconfig/Kubernetes API access, not direct worker-node SSH.
- [ ] Define the namespace, container image, immutable image tag, resource requests and limits, readiness probe, and Service exposure method.
- [ ] Configure Kubernetes and AWS permissions with least privilege for the identity that runs Ansible.
- [ ] Add logging, monitoring, backup, and rollback plans before production use.

## Security and Operations Checklist

- [ ] Store Terraform state remotely with encryption, versioning, and locking.
- [ ] Use least-privilege IAM roles and short-lived AWS credentials.
- [ ] Keep EKS endpoint access private or restricted to trusted networks.
- [ ] Use separate namespaces and access controls for environments and teams.
- [ ] Do not place passwords, tokens, or kubeconfig files in Git or unprotected CI/CD logs.
- [ ] Use Kubernetes Secrets or an external secret-management system for sensitive application configuration.
- [ ] Pin Kubernetes, Terraform provider, Ansible collection, and container-image versions.
- [ ] Define Pod resource requests and limits, readiness probes, and health checks.
- [ ] Monitor cluster health, workloads, audit events, logs, and AWS costs.
- [ ] Use versioned images and keep a documented rollout and rollback procedure.

## Resources

- [AWS EKS documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform EKS module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
- [Kubernetes documentation](https://kubernetes.io/docs/)
- [Ansible Kubernetes collection documentation](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/)
- [AWS CLI `update-kubeconfig` documentation](https://docs.aws.amazon.com/cli/latest/reference/eks/update-kubeconfig.html)

## Topics to Add Later

- A complete, validated Terraform EKS and VPC configuration
- An idempotent Ansible playbook that creates namespace, Deployment, Service, and Ingress resources
- Container registry authentication using Kubernetes image-pull secrets or IAM roles
- Helm chart deployment through Ansible
- CI/CD automation for reviewed Terraform plans and Kubernetes deployments
- Network policies, Pod security, monitoring, and centralised logging
- Blue/green or canary deployment and tested rollback procedures



## Resources