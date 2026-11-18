# Artifact Repository Manager for DevOps — Practical Notes (with Examples)

## Why artifact repositories matter
An artifact repository is the **source of truth for build outputs** (JARs, Docker images, Helm charts, npm packages, Python wheels, Terraform modules, etc.).

In DevOps, it enables:
- reproducible deployments
- versioned rollback
- supply-chain security checks
- traceability from commit → build → artifact → deployment

---

## 1) Core concepts

### Artifact
A packaged build output, for example:
- `myapp-1.4.2.jar`
- `myapp:1.4.2` container image
- `mychart-0.3.1.tgz` Helm chart

### Repository types
- **Hosted**: your own packages/images are published here.
- **Proxy/remote cache**: mirrors external repositories (Docker Hub, Maven Central, npm).
- **Virtual/group**: one endpoint that aggregates hosted + proxy repos.

### Immutability
Prefer immutable version tags/digests:
- Good: `1.4.2`, `2026.11.18-rc1`, `sha-<commit>`
- Risky: overwriting `latest`

---

## 2) Common tools and services

- **Sonatype Nexus Repository**
- **JFrog Artifactory**
- **AWS ECR** (container-focused)
- **GitHub Container Registry (GHCR)**
- **Harbor** (OCI + security-focused)

For your module (`Run_Docker_Droplet_Publish_ECR`), AWS ECR is the key managed registry.

---

## 3) End-to-end flow in CI/CD

```text
Code commit
  -> CI build + tests
  -> Artifact/package creation
  -> Security scan (SCA/SAST/image scan)
  -> Push artifact to repository manager
  -> Tag with semantic + commit metadata
  -> Deploy by digest/version (not floating tags)
```

### Example tagging strategy
For Docker image `myapp`:
- `myapp:1.8.0`
- `myapp:1.8.0-<gitsha>`
- `myapp:main-<buildnumber>`

Deploy production using digest pinning:
- `myapp@sha256:<digest>`

---

## 4) AWS ECR practical workflow

### Authenticate Docker to ECR
```bash
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com
```

### Create repository
```bash
aws ecr create-repository --repository-name myapp
```

### Build, tag, push
```bash
docker build -t myapp:1.0.0 .
docker tag myapp:1.0.0 <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.0.0
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.0.0
```

### Pull on server (Droplet/EC2)
```bash
docker pull <account-id>.dkr.ecr.eu-central-1.amazonaws.com/myapp:1.0.0
```

### Verify image digest
```bash
aws ecr describe-images \
  --repository-name myapp \
  --query 'imageDetails[].{tag:imageTags[0],digest:imageDigest,pushed:imagePushedAt}'
```

---

## 5) Repository structure recommendations

Organize by environment and ownership:
- `team-a/dev/myapp`
- `team-a/prod/myapp`
- `platform/base-images/java17-runtime`

For package repos:
- `maven-releases` (immutable)
- `maven-snapshots` (mutable snapshot workflow)
- `docker-hosted`
- `docker-proxy`
- `docker-group`

---

## 6) Versioning and promotion patterns

### Pattern A: Rebuild per environment (less ideal)
- Build once for dev, rebuild for prod.
- Risk: prod binary may differ from tested artifact.

### Pattern B: Build once, promote same artifact (recommended)
- Build once in CI.
- Promote/tag same artifact from `dev` → `staging` → `prod`.
- Guarantees byte-for-byte parity.

Example promotion tags:
- `myapp:1.9.1-build84`
- add tag `myapp:staging-approved`
- add tag `myapp:prod-approved`

---

## 7) Security best practices

1. **Least privilege IAM/RBAC**
   - CI role: push to specific repos only.
   - Runtime role: pull only.

2. **No long-lived static credentials**
   - Use short-lived tokens/OIDC where possible.

3. **Image scanning**
   - Enable ECR image scanning or external scanners (Trivy/Grype).

4. **Sign artifacts/images**
   - Use Cosign/Sigstore for image signatures.

5. **SBOM generation**
   - Attach SBOM (CycloneDX/SPDX) per build.

6. **Block mutable production tags**
   - Prevent overwriting `prod` tags.

7. **Network controls**
   - Restrict registry access to required principals/networks.

---

## 8) Example IAM policy idea (ECR pull-only)

Grant runtime only what it needs:
- `ecr:GetAuthorizationToken`
- `ecr:BatchGetImage`
- `ecr:GetDownloadUrlForLayer`
- `ecr:BatchCheckLayerAvailability`

Avoid giving runtime any push/delete permissions.

---

## 9) Retention and lifecycle management

Without cleanup, registries grow fast and cost increases.

### ECR lifecycle examples
- Keep last `N` images for non-prod tags.
- Expire untagged images older than 14 days.
- Keep release tags indefinitely or per compliance policy.

Practical baseline:
- Dev repo: retain last 30 tags.
- Staging: retain 60 days.
- Prod: retain releases for 12–24 months (policy-driven).

---

## 10) Reliability and disaster recovery

- Enable cross-region replication where needed.
- Backup metadata/configuration (for self-hosted repos).
- Define recovery objectives:
  - $RTO$ (recovery time objective)
  - $RPO$ (recovery point objective)
- Periodically test restore process.

---

## 11) Observability for artifact repos

Track:
- pull/push success rate
- latency and error rates (4xx/5xx)
- storage growth by repo
- top consumers
- scan findings by severity

Alert examples:
- Push error rate > 5% for 10 minutes.
- Storage usage > 85%.
- High/critical vulnerabilities in production-approved images.

---

## 12) CI/CD integration examples

### Jenkins (conceptual stages)
1. Checkout
2. Build + unit tests
3. Build image
4. Security scan
5. Push to artifact repo
6. Deploy by digest

### GitHub Actions (snippet idea)
```yaml
- name: Build image
  run: docker build -t $IMAGE:$TAG .

- name: Login to ECR
  run: aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY

- name: Push image
  run: |
    docker tag $IMAGE:$TAG $ECR_REGISTRY/$IMAGE:$TAG
    docker push $ECR_REGISTRY/$IMAGE:$TAG
```

Use OIDC-based AWS auth where possible instead of static keys.

---

## 13) Deployment best practice: use digests

Avoid deploying `:latest`.

Use:
```text
<registry>/<repo>/myapp@sha256:<digest>
```

Benefits:
- deterministic rollouts
- simpler rollback
- tamper-evident reference

---

## 14) Common problems and quick fixes

### Problem: `no basic auth credentials`
- Cause: Docker not authenticated to registry.
- Fix: rerun ECR login command and ensure correct AWS profile/region.

### Problem: `manifest unknown`
- Cause: wrong tag/repo name.
- Fix: list tags and verify repository path.

### Problem: pull access denied
- Cause: missing IAM/RBAC permissions.
- Fix: grant pull-only policy to runtime role.

### Problem: image exists but deployment fails
- Cause: wrong architecture (`amd64` vs `arm64`) or bad entrypoint.
- Fix: build multi-arch image with Buildx, verify startup command.

---

## 15) Multi-architecture image example

For mixed environments (Apple Silicon build machine, AMD64 servers):
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t <registry>/myapp:1.2.0 \
  --push .
```

Then verify manifest:
```bash
docker buildx imagetools inspect <registry>/myapp:1.2.0
```

---

## 16) Governance and compliance checklist

- [ ] Naming convention documented (`team/env/app`).
- [ ] Versioning policy documented (SemVer + commit SHA).
- [ ] Production tag immutability enabled.
- [ ] Vulnerability scan gates in CI.
- [ ] Artifact signing policy enabled.
- [ ] SBOM generation + storage defined.
- [ ] Retention/lifecycle policies applied.
- [ ] Access reviews performed periodically.
- [ ] Incident response runbook for compromised artifact.

---

## 17) Minimal runbook for your Module 6 project

1. Build image locally.
2. Authenticate Docker to ECR.
3. Push versioned tag.
4. Record digest.
5. Pull and run exact digest on target host.
6. Validate health endpoint.
7. Keep prior digest for rollback.

Example validation:
```bash
docker run -d --name myapp -p 8080:8080 <registry>/myapp@sha256:<digest>
curl -fsS http://localhost:8080/health
```

Rollback pattern:
```bash
docker stop myapp && docker rm myapp
docker run -d --name myapp -p 8080:8080 <registry>/myapp@sha256:<previous-digest>
```

---

## 18) Suggested additions to this repository

Inside `Module_6_Artifact_Repository_Manager/Run_Docker_Droplet_Publish_ECR/`, add:
- `ecr-login.sh` (safe login helper)
- `build-and-push.sh` (version + digest output)
- `deploy-by-digest.sh` (server-side deterministic deploy)
- `rollback.sh` (switch to previous digest)
- `lifecycle-policy.json` (ECR retention)
- `SECURITY.md` (artifact hardening checklist)

These files make the project recruiter-friendly and reproducible.

---

## Reference links

- AWS ECR docs: https://docs.aws.amazon.com/ecr/
- Docker image best practices: https://docs.docker.com/develop/dev-best-practices/
- OCI image spec: https://github.com/opencontainers/image-spec
- Sigstore Cosign: https://docs.sigstore.dev/cosign/overview/
- Sonatype Nexus docs: https://help.sonatype.com/
- JFrog Artifactory docs: https://jfrog.com/help/
