# Kubernetes Container Orchestration — Theory and Practical DevOps Notes

## Why Kubernetes matters in DevOps
Kubernetes (K8s) is the most common platform for running containerized workloads reliably at scale. It helps DevOps teams automate:
- deployment
- scaling
- self-healing
- service discovery
- rollout/rollback

This makes delivery more predictable and operations more resilient.

---

## 1) Kubernetes core theory

### Cluster model
A Kubernetes cluster has:
- **Control plane** (API server, scheduler, controllers, etcd)
- **Worker nodes** (kubelet, container runtime, kube-proxy)

### Declarative desired state
You declare *what* should run in YAML. Kubernetes continuously reconciles current state to desired state.

### Reconciliation loop
If a Pod dies, controllers create a replacement automatically.

---

## 2) Essential Kubernetes objects

### Pod
Smallest deployable unit; one or more tightly coupled containers.

### Deployment
Manages stateless Pod replicas and rolling updates.

### Service
Stable virtual IP + DNS for Pod access.
- `ClusterIP` (internal)
- `NodePort`
- `LoadBalancer`

### Ingress
HTTP/HTTPS routing into cluster via an Ingress controller.

### ConfigMap and Secret
- ConfigMap: non-sensitive configuration
- Secret: sensitive values (credentials, tokens)

### StatefulSet
For stateful apps requiring stable identity/storage (e.g., databases).

### Job/CronJob
- Job: one-time task
- CronJob: scheduled recurring task

---

## 3) Kubernetes architecture flow (practical)

```text
Git commit
  -> CI builds container image
  -> push image to registry
  -> CD applies manifests/Helm chart
  -> API server stores desired state
  -> scheduler places Pods on nodes
  -> kubelet pulls image and starts containers
  -> Service/Ingress exposes application
```

---

## 4) Key DevOps principles for Kubernetes

1. **Immutable images**: deploy by tag+digest, avoid mutable `latest`.
2. **Small blast radius**: use namespaces and RBAC boundaries.
3. **Health-based traffic**: readiness and liveness probes.
4. **Least privilege**: service accounts and minimal permissions.
5. **Automated validation**: lint/template/dry-run in CI.
6. **Observability-first**: logs, metrics, alerts, traces.

---

## 5) Practical YAML examples

### Deployment + Service (HTTP app)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
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
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 15
            periodSeconds: 20
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

### ConfigMap + Secret usage
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
data:
  APP_MODE: "production"
---
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
type: Opaque
stringData:
  DB_PASSWORD: "replace-me"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: myapp
          image: registry.example.com/myapp:1.2.0
          env:
            - name: APP_MODE
              valueFrom:
                configMapKeyRef:
                  name: myapp-config
                  key: APP_MODE
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: DB_PASSWORD
```

---

## 6) Namespaces, RBAC, and multi-tenancy

### Namespace strategy
Typical environments:
- `dev`
- `staging`
- `prod`

Or per team/application:
- `payments-dev`
- `payments-prod`

### RBAC basics
Grant minimal required actions via Roles/RoleBindings.

Example: read-only Pod access in one namespace:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
```

---

## 7) Networking theory and practice

### Cluster networking
- Every Pod gets an IP.
- Pods can reach each other (subject to policy).
- Services provide stable DNS names.

### NetworkPolicy (important security control)
Default-deny inbound, then allow explicit traffic.

Example allow only app=frontend to app=api on port 8080:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-ingress
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

---

## 8) Storage in Kubernetes

### Core objects
- PV: actual storage resource
- PVC: app request for storage
- StorageClass: dynamic provisioning policy

Use StatefulSet + PVC for databases/caches requiring persistence.

PVC example:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: redis-data
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

---

## 9) Helm and Kustomize in DevOps workflows

### Helm
Templated packaging and release management.
- `helm lint`
- `helm template`
- `helm upgrade --install`

### Kustomize
Patch/overlay-based customization.
- `kubectl kustomize .`
- `kubectl apply -k .`

Both are valid; choose based on team conventions and complexity.

---

## 10) CI/CD pipeline for Kubernetes (recommended)

1. Code commit
2. Unit tests + lint
3. Build image
4. Scan dependencies/image
5. Push image to private registry
6. Render manifests (Helm/Kustomize)
7. Validate (`kubectl --dry-run`, schema checks)
8. Deploy to dev
9. Smoke tests
10. Promote same immutable image to staging/prod

Avoid rebuilding per environment.

---

## 11) Progressive delivery patterns

### Rolling update
Default Deployment strategy, gradual replacement.

### Blue/green
Two environments, switch traffic after validation.

### Canary
Send small percent of traffic to new version, increase gradually.

Tools:
- native K8s + manual routing
- Argo Rollouts / service mesh approaches

---

## 12) Security hardening checklist

- [ ] Non-root containers
- [ ] Drop Linux capabilities
- [ ] `allowPrivilegeEscalation: false`
- [ ] `readOnlyRootFilesystem: true` when possible
- [ ] Pod Security standards enforced
- [ ] Secrets not committed to Git
- [ ] Image scans and admission checks
- [ ] NetworkPolicies applied
- [ ] RBAC least privilege
- [ ] TLS on ingress and service-to-service where required

Pod security context example:
```yaml
securityContext:
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
```

---

## 13) Observability in Kubernetes

### What to collect
- Pod/container logs
- Node/Pod metrics (CPU/memory)
- app metrics (latency, error rate, throughput)
- traces for request paths

### Practical stack
- Prometheus + Alertmanager
- Grafana dashboards
- Loki/ELK for logs
- OpenTelemetry for traces

High-value alerts:
- CrashLoopBackOff
- high error rate
- saturation (CPU/memory)
- unavailable service endpoints

---

## 14) Reliability and SRE alignment

Define Service Level Objectives (SLOs) such as:
- Availability: 99.9%
- P95 latency < 300ms
- Error rate < 1%

Use error budgets to balance release speed and reliability.

Operational basics:
- PodDisruptionBudgets
- anti-affinity for HA
- multi-zone scheduling where available
- tested backup and restore for stateful systems

---

## 15) Common kubectl commands (practical cheatsheet)

```bash
# Context and cluster
kubectl config current-context
kubectl get nodes

# Workloads
kubectl get pods -A
kubectl get deploy,svc -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>

# Debug
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl logs -f deployment/<name> -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp

# Exec
kubectl exec -it <pod> -n <namespace> -- sh

# Port-forward
kubectl port-forward service/<name> 8080:80 -n <namespace>

# Validation
kubectl apply --dry-run=client --validate=true -f manifest.yaml
```

---

## 16) Troubleshooting runbook

When something fails:
1. Check rollout status.
2. Inspect Pod events and logs.
3. Confirm image pull/auth (`ImagePullBackOff`).
4. Check readiness/liveness probe failures.
5. Confirm Service selectors match Pod labels.
6. Verify DNS and network policy paths.
7. Roll back to known good version if needed.

Example rollback:
```bash
kubectl rollout undo deployment/myapp -n prod
```

---

## 17) Common anti-patterns to avoid

- Deploying mutable `latest` to production
- No resource requests/limits
- Missing probes
- Running everything in `default` namespace
- Cluster-admin permissions for app service accounts
- Secrets in Git
- No backup/restore tests for stateful apps
- No staging environment before production

---

## 18) Suggested additions for Module 10

Useful scripts/files to add:
- `scripts/k8s-validate.sh` (lint/template/dry-run)
- `scripts/k8s-smoke-test.sh`
- `scripts/k8s-rollout-check.sh`
- `security-baseline.md` per project
- `runbooks/incident-response.md`

These make demos reproducible and recruiter-friendly.

---

## 19) Learning progression (practical path)

1. Deploy one stateless app with Deployment + Service.
2. Add probes and resources.
3. Add Ingress and TLS.
4. Add ConfigMap/Secret.
5. Add Helm/Kustomize packaging.
6. Add CI validation and CD rollout.
7. Add observability and alerting.
8. Add NetworkPolicy and RBAC hardening.
9. Add stateful workloads and backup strategy.

---

## References

- Kubernetes docs: https://kubernetes.io/docs/
- Helm docs: https://helm.sh/docs/
- Kustomize docs: https://kubectl.docs.kubernetes.io/references/kustomize/
- CNCF Cloud Native Trail Map: https://github.com/cncf/trailmap
- Pod Security Standards: https://kubernetes.io/docs/concepts/security/pod-security-standards/
