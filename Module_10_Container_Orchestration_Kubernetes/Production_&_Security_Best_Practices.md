# Kubernetes Production and Security Best Practices

## Overview

This guide captures the production practices used when deploying containerised microservices to Kubernetes. The goal is to deliver workloads that are **repeatable, observable, resilient, and secure by default**—not merely workloads that start successfully.

These practices are especially relevant to the microservices deployment exercise in this module. They apply whether the cluster is self-managed or provided by a managed service such as Amazon EKS, Linode Kubernetes Engine (LKE), or Azure Kubernetes Service (AKS).

## Production Readiness Checklist

| Area | Outcome | Key controls |
| --- | --- | --- |
| Image delivery | Repeatable deployments and fast rollback | Immutable image references, image registry, CI validation |
| Application health | Traffic reaches only healthy, ready Pods | Startup, liveness, and readiness probes |
| Capacity | Predictable scheduling and protected nodes | CPU/memory requests and limits |
| Availability | Service remains available during failures and releases | Multiple replicas, spreading, disruption budgets |
| Networking | Minimal and intentional exposure | ClusterIP by default, Ingress/load balancer at the edge, network policies |
| Organisation | Clear ownership and safe access boundaries | Labels, namespaces, RBAC |
| Security | Reduced supply-chain and runtime risk | Image scanning, non-root execution, least privilege, current patches |

## 1. Use Immutable Container Image References

Each container image should use a specific, immutable version, such as `1.4.2`, or ideally a digest such as `@sha256:...`. Avoid mutable tags such as `latest` in production.

**Why it matters**

- Every deployment can be traced to the exact artifact that was tested and approved.
- Rollbacks are reliable because the previous image is still identifiable.
- A Pod restart cannot silently pull a different build under the same tag.

**Recommended approach**

- Build and scan the image in CI.
- Publish a versioned image only after checks pass.
- Promote the same image digest from test to production rather than rebuilding it.
- Record the image version in deployment metadata or release notes.

```yaml
containers:
  - name: checkout-service
    image: registry.example.com/checkout-service:1.4.2
    imagePullPolicy: IfNotPresent
```

## 2. Configure Startup, Liveness, and Readiness Probes

Kubernetes probes communicate the application’s health to the platform. They are complementary rather than interchangeable.

| Probe | Purpose | Kubernetes action when it fails |
| --- | --- | --- |
| `startupProbe` | Allows a slow-starting application time to initialise | Delays liveness/readiness checks until startup succeeds |
| `livenessProbe` | Detects a running container that is stuck or unrecoverable | Restarts the container |
| `readinessProbe` | Confirms that the application can serve requests | Removes the Pod from Service endpoints; does not restart it |

Without a readiness probe, Kubernetes may route traffic to a container as soon as it starts, even if dependencies, caches, or migrations are still incomplete. Conversely, a liveness probe should not fail for a temporary dependency outage if restarting the application will not improve the situation.

```yaml
startupProbe:
  httpGet:
    path: /health/startup
    port: 8080
  failureThreshold: 30
  periodSeconds: 5
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

## 3. Define CPU and Memory Requests and Limits

Every production container should declare resource requests and limits for CPU and memory.

- **Requests** are the resources Kubernetes reserves when scheduling the Pod. They help the scheduler place workloads on nodes with sufficient capacity.
- **Limits** are the maximum resources a container may use. Exceeding a memory limit normally results in the container being terminated with `OOMKilled`; a CPU limit can cause throttling rather than termination.

Requests and limits protect shared worker nodes from a single faulty or unexpectedly busy service. Set them using observed application metrics and load tests, then review them as workload characteristics change.

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

For services with changing demand, combine sensible requests with a Horizontal Pod Autoscaler (HPA). Avoid setting arbitrarily low limits simply to fit more Pods on a node; CPU throttling and memory restarts are production incidents in disguise.

## 4. Build for Availability and Safe Rollouts

A Deployment with one replica creates a single point of failure: an application becomes unavailable while its only Pod restarts, is rescheduled, or is updated.

**Baseline availability controls**

- Run at least two replicas for user-facing, stateless services.
- Spread replicas across nodes and, where applicable, availability zones using topology-spread constraints or pod anti-affinity.
- Use rolling-update settings that preserve available capacity during releases.
- Define a PodDisruptionBudget (PDB) to prevent voluntary maintenance from evicting too many replicas at once.
- Use HPA when traffic is variable and cluster capacity allows it.

Replication alone is not enough: replicas placed on the same node can still fail together. The cluster itself should also have sufficient nodes and be designed for the availability objectives of the service.

## 5. Expose Services Deliberately

Use the least-exposed service type that meets the communication requirement.

| Requirement | Preferred mechanism |
| --- | --- |
| Pod-to-Pod communication inside the cluster | `ClusterIP` Service |
| Public HTTP/HTTPS application access | Ingress or Gateway API backed by a load balancer |
| Direct external access to a specific service | `LoadBalancer` Service, when justified |
| Local development or temporary diagnostics | `NodePort` only when necessary |

`NodePort` opens a port on every worker node. It is useful in limited scenarios but is rarely the preferred production entry point because it expands the network exposure and complicates traffic management. Keep internal services as `ClusterIP`, publish only the intended edge service, and enforce allowed traffic with NetworkPolicies where the CNI supports them.

## 6. Use Consistent Labels and Annotations

Labels are key-value pairs used to identify, select, organise, and operate Kubernetes resources. A Service, for example, selects Pods through matching labels. Consistent labels also improve monitoring dashboards, cost analysis, policy enforcement, and incident response.

Use meaningful, stable labels based on the Kubernetes recommended conventions:

```yaml
metadata:
  labels:
    app.kubernetes.io/name: checkout-service
    app.kubernetes.io/component: backend
    app.kubernetes.io/part-of: online-boutique
    app.kubernetes.io/version: "1.4.2"
    app.kubernetes.io/managed-by: helm
```

Use annotations for non-identifying metadata, such as a CI build URL, deployment timestamp, or an Ingress controller configuration. Do not place secrets in either labels or annotations.

## 7. Isolate Workloads with Namespaces and RBAC

Namespaces provide a logical boundary for resources. They make it easier to separate environments, teams, or applications and to apply policies consistently.

**Recommended controls**

- Do not deploy application workloads to the `default` namespace.
- Use a clear namespace strategy, for example `development`, `staging`, and `production`, or dedicated namespaces per application team.
- Apply ResourceQuotas and LimitRanges to protect shared clusters from unbounded consumption.
- Grant permissions using namespace-scoped `Role` and `RoleBinding` objects wherever possible.
- Use a dedicated ServiceAccount per workload; avoid the default ServiceAccount for applications.

RBAC should follow least privilege: grant only the verbs (`get`, `list`, `watch`, and so on) and resource types a person, pipeline, or workload genuinely needs. Prefer `Role` over cluster-wide `ClusterRole` where scope permits.

## 8. Secure the Software Supply Chain

Container security starts before a Pod is scheduled.

- Use trusted, maintained base images and keep them current.
- Minimise the image: include only runtime dependencies and use multi-stage builds where appropriate.
- Generate a software bill of materials (SBOM) and scan both application dependencies and image layers for vulnerabilities.
- Fail or require review for critical vulnerabilities according to a documented risk policy.
- Sign images and verify signatures at admission when the organisation supports it.
- Store images in a private registry with authenticated, audited access.

> **Note:** Vulnerability scanning reduces risk; it does not replace patching. Prioritise fixes using severity, exploitability, exposure, and the availability of a remediation.

## 9. Run Containers as Non-Root with Restricted Privileges

Containers should not run as root unless there is a documented technical requirement. Root in a container is not automatically root on the node, but it increases the impact of a container escape or misconfiguration.

Set a restrictive security context and verify that the image supports it:

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    fsGroup: 10001
  containers:
    - name: checkout-service
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

Also avoid privileged containers, host networking, host PID/IPC namespaces, and host-path mounts unless they are formally justified and protected by policy. Pod Security Admission, Kyverno, or Gatekeeper can enforce these guardrails at deployment time.

## 10. Protect Configuration and Secrets

Use ConfigMaps for non-sensitive configuration and Secrets for credentials, tokens, certificates, and connection strings. A Kubernetes Secret is base64-encoded—not automatically encrypted for every threat model.

- Enable encryption at rest for Secrets in the cluster control plane.
- Restrict Secret access with RBAC and namespace boundaries.
- Integrate an external secret manager for high-value or frequently rotated credentials.
- Mount only the secrets required by each workload and rotate them regularly.
- Never commit real secrets, kubeconfig files, private keys, or tokens to source control.

## 11. Keep the Platform Patched and Observable

Kubernetes, node operating systems, container runtimes, and add-ons require a regular maintenance lifecycle. Managed Kubernetes services simplify upgrades, but teams still own compatibility testing and safe rollout planning.

Before an upgrade, validate application compatibility in a non-production cluster, check deprecated API usage, and confirm node upgrade capacity. Upgrade worker nodes gradually while replicas and disruption budgets preserve availability.

Production readiness also requires observability. At a minimum, collect:

- application logs with request or correlation identifiers;
- metrics for latency, traffic, errors, and saturation (the RED/USE signals);
- Kubernetes events, Pod restart counts, probe failures, and resource utilisation;
- alerts that are actionable and linked to runbooks.

## Review Before Each Release

Before deploying, confirm the following:

- [ ] Image reference is immutable and has passed the security policy.
- [ ] Probes match the application's real startup and dependency behaviour.
- [ ] CPU and memory requests/limits are based on evidence.
- [ ] The workload has enough replicas, safe rollout settings, and a PDB where appropriate.
- [ ] Only required network paths are exposed.
- [ ] Labels, namespace, ServiceAccount, and RBAC are correctly scoped.
- [ ] The Pod runs as non-root with no unnecessary privileges.
- [ ] Secrets are protected and absent from Git history and manifests.
- [ ] Dashboards, alerts, and rollback procedures are ready before release.

## Key Takeaway

Production Kubernetes is a combination of application design, platform controls, and operational discipline. Applying these practices consistently creates deployments that are easier to audit, safer to change, and more reliable for users.
