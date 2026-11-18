# Amazon EKS and `eksctl` — Kubernetes Orchestration Theory + Practical DevOps Notes

## Why EKS + eksctl matters
Amazon EKS gives you managed Kubernetes control planes, while `eksctl` gives you a fast, declarative way to create and manage EKS clusters and node groups.

For DevOps, this combination helps with:
- faster cluster provisioning
- standardized environments
- safer operational workflows
- cleaner CI/CD integration to Kubernetes on AWS

---

## 1) EKS fundamentals (theory)

### Shared responsibility model
In EKS:
- AWS manages Kubernetes control plane availability/patching.
- You manage worker compute, workload security, networking design, and operations.

### EKS architecture components
- **Control plane**: API server, etcd, scheduler, controllers (managed by AWS)
- **Data plane**:
  - managed node groups (EC2)
  - or AWS Fargate (serverless Pods)
- **VPC networking**: subnets, route tables, NAT/IGW, security groups
- **IAM integration**: roles for cluster, nodes, and workloads (IRSA)

### Operational takeaway
EKS reduces control-plane burden but does not remove DevOps responsibilities for cost, security, reliability, and release management.

---

## 2) `eksctl` essentials (theory)

`eksctl` is a CLI built for EKS lifecycle tasks.

Common capabilities:
- create/delete clusters
- create managed node groups
- create Fargate profiles
- enable IAM OIDC provider
- create IAM service accounts (IRSA)

### Why use `eksctl`
- less boilerplate than manual AWS CLI
- reproducible YAML-based cluster config
- safer than long one-line commands

---

## 3) Provisioning approaches in DevOps

### Approach A: `eksctl` only
- best for quick bootstrap and learning/sandbox
- fast iteration

### Approach B: Terraform only
- better for large enterprises and policy-heavy IaC

### Approach C: Hybrid
- bootstrap via `eksctl`, then codify mature state in Terraform
- common transitional pattern

---

## 4) Practical prerequisites checklist

Before creating clusters:

```bash
aws sts get-caller-identity
aws configure list
eksctl version
kubectl version --client
```

Required permissions typically include:
- EKS
- EC2/VPC
- IAM
- CloudFormation
- Auto Scaling
- ELB

Also ensure budget awareness: EKS control plane + EC2/Fargate + NAT gateways are billable.

---

## 5) Minimal `eksctl` cluster creation example

```bash
eksctl create cluster \
  --name demo-eks \
  --region eu-central-1 \
  --version 1.29 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

Verify:

```bash
kubectl config current-context
kubectl get nodes
kubectl get pods -A
```

---

## 6) Recommended `eksctl` config-file pattern

Prefer config files over long commands.

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: demo-eks
  region: eu-central-1
  version: "1.29"

managedNodeGroups:
  - name: ng-app
    instanceType: t3.medium
    minSize: 1
    maxSize: 3
    desiredCapacity: 2
    privateNetworking: true

iam:
  withOIDC: true

cloudWatch:
  clusterLogging:
    enableTypes: ["api", "audit", "authenticator"]
```

Create:

```bash
eksctl create cluster -f cluster.yaml
```

Why this is better:
- reviewable in PRs
- repeatable across team
- easier drift detection

---

## 7) Networking design for EKS (DevOps angle)

### Good baseline
- private subnets for nodes
- public subnets for load balancers only when needed
- NAT gateway for outbound pulls/updates
- restricted security-group ingress

### API endpoint access choices
- `publicAccess=true` for easier admin (sandbox only, with CIDR restriction)
- `privateAccess=true` for production-grade control-plane isolation

Never leave broad admin access (`0.0.0.0/0`) unless absolutely temporary and controlled.

---

## 8) Managed Node Groups vs Fargate

### Managed Node Groups (EC2)
Pros:
- full Kubernetes feature compatibility
- daemonsets supported
- predictable for mixed workloads

Cons:
- node patching/lifecycle operations still needed

### Fargate
Pros:
- no node management
- good for bursty/smaller stateless workloads

Cons:
- fewer workload patterns
- cost can be higher for steady heavy workloads
- daemonset limitations

Rule of thumb:
- use EC2 node groups for core platform services
- use Fargate selectively for suitable app workloads

---

## 9) IAM and IRSA (critical for security)

### Principle
Do not put static AWS credentials in Pods.

Use IRSA (IAM Roles for Service Accounts):
1. enable OIDC provider
2. create Kubernetes service account mapped to IAM role
3. grant least-privilege IAM policy

Example:

```bash
eksctl utils associate-iam-oidc-provider \
  --region eu-central-1 \
  --cluster demo-eks \
  --approve

eksctl create iamserviceaccount \
  --name app-sa \
  --namespace default \
  --cluster demo-eks \
  --attach-policy-arn arn:aws:iam::<account-id>:policy/MyAppS3ReadOnly \
  --approve
```

---

## 10) Private image pull patterns (ECR and Docker Hub)

### ECR (preferred on AWS)
- nodes typically pull via node IAM role permissions
- optional imagePullSecret pattern also works

### Docker Hub private registry
Create image pull secret in namespace:

```bash
kubectl create secret docker-registry my-registry-key \
  --docker-server=docker.io \
  --docker-username=<user> \
  --docker-password=<token>
```

Then reference in Deployment:

```yaml
spec:
  template:
    spec:
      imagePullSecrets:
        - name: my-registry-key
```

---

## 11) EKS CI/CD integration blueprint

1. Build/test app in CI
2. Build and scan image
3. Push to ECR (or approved private registry)
4. Update Kubernetes manifests/Helm values with immutable image tag/digest
5. Deploy to EKS (dev)
6. Run smoke tests
7. Promote same image to staging/prod

Do not rebuild per environment.

---

## 12) Example deployment manifest for EKS workloads

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: app-sa
      containers:
        - name: myapp
          image: <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.2.0
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
```

---

## 13) Cost and reliability guidance

### Cost hotspots in EKS labs
- EKS control plane hourly cost
- NAT gateway hourly + data processing
- EC2 worker nodes
- load balancers
- CloudWatch logs

### Practical cost controls
- use smallest viable node size in sandbox
- single NAT gateway in learning envs
- clean up load balancers and EBS leftovers
- stop/delete non-prod clusters after demos

### Reliability controls
- multi-AZ node groups
- PodDisruptionBudgets
- cluster autoscaler where needed
- tested rollback strategy

---

## 14) Observability on EKS

Recommended baseline:
- Prometheus + Alertmanager + Grafana
- container insights / CloudWatch metrics logs
- centralized app logs

High-value alerts:
- node not ready
- pod crashlooping
- high API server latency
- deployment rollout timeout

---

## 15) EKS troubleshooting runbook

When something fails:

1. Confirm kube context:
```bash
kubectl config current-context
```
2. Check nodes and core pods:
```bash
kubectl get nodes
kubectl get pods -A
```
3. Inspect workload:
```bash
kubectl describe pod <pod> -n <ns>
kubectl logs <pod> -n <ns>
```
4. Check image pull issues (`ImagePullBackOff`) and registry auth.
5. Verify service selectors/endpoints:
```bash
kubectl get svc,endpoints -n <ns>
```
6. Check AWS-side resources (ELB, SG rules, subnets).

---

## 16) Security hardening checklist for EKS

- [ ] private cluster endpoint or restricted CIDRs
- [ ] least-privilege IAM roles (cluster/node/workload)
- [ ] IRSA for workloads
- [ ] no static cloud keys in manifests
- [ ] image scanning + signed images where possible
- [ ] Kubernetes RBAC least privilege
- [ ] NetworkPolicies for east-west traffic control
- [ ] secrets via AWS Secrets Manager/External Secrets or equivalent
- [ ] audit/API/authenticator logs enabled

---

## 17) Operational command cheat sheet

```bash
# Cluster lifecycle
eksctl get cluster --region eu-central-1
eksctl delete cluster --name demo-eks --region eu-central-1

# Nodegroups
eksctl get nodegroup --cluster demo-eks --region eu-central-1
eksctl create nodegroup --cluster demo-eks --name extra-ng --nodes 2

# Fargate profile
eksctl create fargateprofile \
  --cluster demo-eks \
  --name fp-dev \
  --namespace dev

# Kubernetes checks
kubectl get deploy,svc,pods -A
kubectl rollout status deployment/myapp -n default
kubectl get events -A --sort-by=.lastTimestamp | tail -50
```

---

## 18) Common anti-patterns to avoid

- using mutable `latest` image tags in production
- broad IAM permissions like `*:*`
- public API endpoint open to all IPs
- no readiness/liveness probes
- running production with no autoscaling boundaries
- skipping backup/restore testing for stateful workloads
- manual, undocumented infrastructure changes outside IaC

---

## 19) Suggested additions for your Module 11 folder

Useful files to add:
- `cluster.yaml` (authoritative eksctl config)
- `scripts/create-cluster.sh`
- `scripts/delete-cluster.sh`
- `scripts/bootstrap-oidc-irsa.sh`
- `scripts/validate-eks.sh` (context, nodes, addons, namespace checks)
- `runbooks/eks-incident-response.md`

This makes the module portfolio-ready and reproducible.

---

## 20) Learning progression (EKS-focused)

1. Create cluster with `eksctl` config file.
2. Deploy stateless app with probes and resources.
3. Configure private registry pull (ECR or Docker Hub secret).
4. Add CI/CD deployment to EKS.
5. Add IRSA and least-privilege IAM.
6. Add observability and alerting.
7. Add autoscaling and reliability controls.
8. Add policy/security hardening and cost governance.

---

## References

- EKS docs: https://docs.aws.amazon.com/eks/
- eksctl docs: https://eksctl.io/
- EKS best practices guide: https://aws.github.io/aws-eks-best-practices/
- Kubernetes docs: https://kubernetes.io/docs/
- AWS Well-Architected: https://docs.aws.amazon.com/wellarchitected/
