# Cloud-Native and Cloud Infrastructure — DevOps Theory + Practical Notes

## Why this matters
Cloud-native DevOps is about building systems that are:
- resilient
- scalable
- observable
- secure by default
- automated end-to-end

In practice, this means combining architecture patterns, infrastructure automation, CI/CD, and operations discipline.

---

## 1) Cloud-native fundamentals

### What “cloud-native” means
Cloud-native applications are designed to run well in dynamic cloud environments (public, private, hybrid) using:
- containers
- orchestration (Kubernetes/ECS)
- microservices/API-first design
- automated delivery
- elastic infrastructure

### 12-factor influence (high value summary)
1. Codebase in version control
2. Explicit dependencies
3. Config in environment
4. Backing services treated as attached resources
5. Build/release/run separation
6. Stateless processes
7. Port binding
8. Concurrency via process model
9. Fast startup and graceful shutdown
10. Dev/prod parity
11. Logs as event streams
12. Admin tasks as one-off processes

---

## 2) Cloud service models (IaaS, PaaS, SaaS)

- **IaaS**: You manage VM OS/network/runtime (e.g., EC2).
- **PaaS**: Provider manages platform/runtime abstraction (e.g., Elastic Beanstalk/App Service).
- **SaaS**: You consume software managed by vendor.

DevOps impact:
- More control in IaaS, more operational burden.
- More speed in PaaS, less low-level control.

---

## 3) Core cloud infrastructure building blocks

### Compute
- EC2/VMs
- Containers (ECS/EKS/Kubernetes)
- Serverless functions

### Networking
- VPC/VNet
- subnets (public/private)
- route tables
- Internet gateway / NAT gateway
- load balancers
- security groups / network ACLs

### Storage
- Object storage (S3)
- Block storage (EBS)
- File storage (EFS)

### Data services
- Managed relational DBs (RDS)
- NoSQL services (DynamoDB)
- Caches (Redis/ElastiCache)

### Identity and security
- IAM users/roles/policies
- KMS key management
- secrets manager / parameter store

---

## 4) Reference architecture pattern (typical web app)

```text
Internet
  -> CDN (optional)
  -> WAF
  -> Load Balancer
  -> App tier (containers/EC2)
  -> Data tier (RDS/Redis)
  -> Object storage (assets/backups)

Ops plane:
  -> CI/CD pipeline
  -> IaC state backend
  -> Monitoring/logging/alerting
  -> Secret and key management
```

Key objective: isolate blast radius and enforce least privilege between tiers.

---

## 5) Infrastructure as Code (IaC) in DevOps

### Why IaC
- reproducible environments
- auditable change history
- safer review/approval workflow
- less manual drift

### Common tools
- Terraform
- AWS CloudFormation/CDK
- Bicep (Azure)

### Terraform example (AWS EC2)
```hcl
provider "aws" {
  region = "eu-central-1"
}

resource "aws_instance" "app" {
  ami           = "ami-xxxxxxxx"
  instance_type = "t3.micro"
  tags = {
    Name = "devops-app"
    Env  = "dev"
  }
}
```

### IaC best practices
- remote state + locking
- no hardcoded secrets
- small reusable modules
- plan before apply
- enforce policy checks in CI

---

## 6) Environment strategy

Recommended separation:
- `dev`
- `staging`
- `prod`

Each should have:
- separate cloud accounts/subscriptions when possible
- distinct IAM boundaries
- explicit promotion path (artifact/image based)

Do not rebuild artifacts per environment; promote the same immutable artifact.

---

## 7) Cloud-native CI/CD pipeline blueprint

Typical flow:
1. Commit / PR
2. Lint + unit tests
3. Build artifact/container
4. Vulnerability and policy scans
5. Push to artifact/container registry
6. Deploy to dev automatically
7. Run smoke/integration tests
8. Promote to staging/prod via approval policy

### Example release tag model
$$
\text{Tag} = \text{SemVer} + "-ci." + \text{BuildNumber}
$$

Example: `2.3.1-ci.105`

Deploy by digest:
`registry/myapp@sha256:<digest>`

---

## 8) Kubernetes/ECS practical patterns

### Kubernetes baseline concepts
- Pod
- Deployment
- Service
- Ingress
- ConfigMap + Secret
- HPA (autoscaling)

### Deployment example (snippet)
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
      containers:
        - name: myapp
          image: registry.example.com/myapp:1.2.0
          ports:
            - containerPort: 8080
          readinessProbe:
            httpGet:
              path: /health
              port: 8080
```

### Why readiness/liveness matters
- readiness controls traffic routing
- liveness handles stuck process recovery

---

## 9) Observability: logs, metrics, traces

### Three pillars
1. Logs
2. Metrics
3. Traces

### Practical stack examples
- Metrics: Prometheus
- Dashboards: Grafana
- Logs: Loki / ELK / CloudWatch Logs
- Traces: OpenTelemetry + Tempo/Jaeger/X-Ray

### High-value SLO indicators
- latency (P95/P99)
- error rate
- traffic rate
- saturation (CPU/memory/queue)

Alert on user-impacting symptoms, not only infrastructure noise.

---

## 10) Security in cloud-native DevOps

### Identity and access
- Prefer roles over long-lived access keys.
- Enforce least privilege policies.
- Separate human and machine identities.

### Secrets management
- Use Secrets Manager / Parameter Store / Vault.
- Never commit secrets to Git.

### Network security
- private subnets for internal services
- ingress allow-list and WAF
- egress restrictions where possible

### Supply-chain security
- dependency scanning (SCA)
- image scanning
- artifact signing
- SBOM generation

---

## 11) Reliability and resilience patterns

### Design patterns
- health checks
- retries with backoff
- circuit breaker
- timeout budgets
- idempotent operations
- graceful shutdown

### Multi-AZ and backup strategy
- run critical workloads across AZs
- automated snapshots/backups
- periodic restore testing

Define:
- $RTO$ (recovery time objective)
- $RPO$ (recovery point objective)

---

## 12) Cost optimization (FinOps-aware DevOps)

1. Right-size compute.
2. Auto-scale intelligently.
3. Turn off non-prod outside working hours.
4. Use storage lifecycle policies.
5. Monitor idle resources and orphan volumes/IPs.
6. Track unit economics (cost per request/build/env).

Example checks:
- Unattached volumes
- Idle load balancers
- Over-provisioned dev clusters

---

## 13) Practical AWS CLI examples for infrastructure ops

### Identity and region sanity checks
```bash
aws sts get-caller-identity
aws configure list
aws ec2 describe-availability-zones --region eu-central-1
```

### EC2 listing with useful filters
```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{Id:InstanceId,Type:InstanceType,AZ:Placement.AvailabilityZone,Name:Tags[?Key=='Name']|[0].Value}" \
  --output table
```

### Security group ingress example (SSH from one IP)
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 203.0.113.10/32
```

### ECR login/push example
```bash
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

docker tag myapp:1.0.0 <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.0.0
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.0.0
```

---

## 14) Incident response mini-runbook (cloud production)

1. Detect alert and define impact scope.
2. Check recent deploy/change/events.
3. Validate service health endpoints.
4. Inspect logs/metrics/traces.
5. Mitigate quickly (rollback/scale/failover).
6. Confirm recovery with SLO metrics.
7. Write post-incident review and prevention tasks.

Priority order:
1. restore service
2. preserve evidence
3. identify root cause
4. automate prevention

---

## 15) Common anti-patterns to avoid

- Manual infrastructure changes outside IaC
- Shared root credentials
- Publicly exposed databases
- Deploying mutable `latest` image tags to prod
- Missing health checks
- No rollback plan
- Alerts without runbooks
- No backup restore testing

---

## 16) DevOps cloud governance checklist

- [ ] IaC for all major infrastructure components
- [ ] Separate environments/accounts
- [ ] Least-privilege IAM and role usage
- [ ] Secrets manager integrated
- [ ] CI/CD includes security scans and policy checks
- [ ] Immutable artifact/image promotion
- [ ] Monitoring + alerting + dashboards defined
- [ ] Backup and restore tested
- [ ] Cost budget alerts configured
- [ ] Incident runbooks documented

---

## 17) Practical starter scripts to add in Module 9

Recommended additions:
- `scripts/aws-auth-check.sh`
- `scripts/ec2-bootstrap.sh`
- `scripts/ecr-login.sh`
- `scripts/deploy-by-digest.sh`
- `scripts/rollback.sh`
- `scripts/cloud-healthcheck.sh`

Each script should include:
- strict mode (`set -euo pipefail`)
- input validation
- clear logs
- non-zero exit on failure

---

## 18) Suggested learning progression

1. Start with EC2 manual deployment.
2. Add container registry (ECR) publishing.
3. Introduce CI build/test/image pipeline.
4. Add CD with approval gates.
5. Move to IaC-provisioned infra.
6. Add Kubernetes/ECS orchestration.
7. Add observability + SLO-driven alerts.
8. Add security hardening and policy-as-code.

This progression mirrors real-world DevOps maturity.

---

## References

- AWS Well-Architected Framework: https://docs.aws.amazon.com/wellarchitected/
- AWS DevOps guidance: https://aws.amazon.com/devops/
- Kubernetes docs: https://kubernetes.io/docs/
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Terraform docs: https://developer.hashicorp.com/terraform/docs
- 12-Factor App: https://12factor.net/
