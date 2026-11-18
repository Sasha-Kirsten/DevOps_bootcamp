# Continuous Integration (CI) Theory and Practical Notes for DevOps

## Why CI matters
Continuous Integration is the practice of frequently merging small code changes into a shared branch and validating every change automatically.

CI helps DevOps teams:
- detect issues early
- reduce integration risk
- keep software releasable
- enforce security and quality gates
- improve delivery speed and confidence

---

## 1) Core CI theory

### Definition
CI is a development and operations practice where each code change triggers an automated pipeline that builds, tests, and validates the application.

### CI goals
1. Fast feedback (minutes, not hours)
2. Deterministic builds (same input → same output)
3. High signal quality (clear pass/fail reason)
4. Safe automation (least privilege, no secret leakage)

### CI vs CD
- **CI**: automate build/test/validation of changes.
- **CD (Delivery/Deployment)**: automate release readiness or production rollout.

CI is the foundation; CD builds on top of it.

---

## 2) CI pipeline lifecycle (reference model)

Typical stages:
1. **Checkout** source
2. **Setup** runtime/toolchain
3. **Install dependencies**
4. **Static checks** (lint, format, type checks)
5. **Unit tests**
6. **Build/package** artifact
7. **Security checks** (SAST/SCA/container scan)
8. **Publish artifacts** (optional in CI)
9. **Report + notify**

A healthy CI pipeline is short, repeatable, and has meaningful gates.

---

## 3) CI architecture patterns

### Trunk-based development + short-lived branches
- Merge to main frequently.
- Keep branch lifetime short.
- Run PR checks before merge.

### Multibranch CI
Each branch gets isolated pipeline execution.
- Great for feature branches and pull requests.
- Avoid branch-specific hidden behavior unless intentional.

### Build once, promote artifact
- Build artifact exactly once in CI.
- Reuse same immutable artifact for staging/prod.
- Do not rebuild separately per environment.

---

## 4) CI quality gates (must-have)

Use clear gate order:
1. Syntax/lint
2. Unit tests
3. Package build
4. Security scan
5. Artifact publish (if all pass)

Fail fast principle:
- stop pipeline as soon as a gate fails
- save runner time and developer time

---

## 5) Practical Jenkins pipeline design

### Declarative Jenkinsfile example
```groovy
pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  environment {
    APP_NAME = 'myapp'
    VERSION  = "1.0.0-ci.${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Lint') {
      steps {
        sh 'mvn -q -DskipTests=true checkstyle:check || true'
      }
    }

    stage('Build + Unit Test') {
      steps {
        sh 'mvn --batch-mode clean verify'
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
        }
      }
    }

    stage('Build Image') {
      steps {
        sh 'docker build --tag ${APP_NAME}:${VERSION} .'
      }
    }

    stage('Security Scan (example)') {
      steps {
        sh 'trivy image --exit-code 0 ${APP_NAME}:${VERSION}'
      }
    }
  }

  post {
    success {
      echo "Pipeline succeeded: ${APP_NAME}:${VERSION}"
    }
    failure {
      echo 'Pipeline failed. Check stage logs and test reports.'
    }
  }
}
```

### Jenkins best practices
- Keep controller lightweight; run builds on agents.
- Store pipeline as code (`Jenkinsfile`) in Git.
- Use shared libraries for reusable steps.
- Avoid heavy Groovy logic; do heavy work in shell/tooling on agent.
- Put manual `input` outside `node/agent` when possible.

---

## 6) Practical GitHub Actions CI design

### Basic CI workflow example
```yaml
name: ci

on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-test:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'
          cache: maven

      - name: Build and test
        run: mvn --batch-mode clean verify

      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: surefire-reports
          path: target/surefire-reports
```

### GitHub Actions best practices
- Use `concurrency` to cancel outdated runs.
- Cache dependencies safely (lockfile/hash-based).
- Use path filters for docs-only changes.
- Use reusable workflows for consistency across repos.

---

## 7) CI for containers

### CI container steps
1. Build container image
2. Run tests
3. Scan image vulnerabilities
4. Push to registry with immutable tag
5. Record image digest

### Example commands
```bash
docker build -t myapp:1.0.0-ci.42 .
trivy image myapp:1.0.0-ci.42

docker tag myapp:1.0.0-ci.42 registry.example.com/myapp:1.0.0-ci.42
docker push registry.example.com/myapp:1.0.0-ci.42
```

Deploy later by digest:
```text
registry.example.com/myapp@sha256:<digest>
```

---

## 8) Versioning strategy in CI

### Recommended approach
- Keep `VERSION` file for release baseline (`MAJOR.MINOR.PATCH`).
- Generate CI build metadata using build number or commit SHA.

Formula example:
$$
\text{CI Version} = \text{BaseVersion} + "-ci." + \text{BuildNumber}
$$

Example:
- Base version: `1.4.0`
- Build number: `83`
- Result: `1.4.0-ci.83`

Benefits:
- immutable tags
- clear traceability
- no source mutation required

---

## 9) Testing strategy in CI

### Test pyramid in CI
- Unit tests: always
- Integration tests: often (or gated by branch)
- End-to-end tests: targeted/scheduled due to cost

### Practical split
- PR pipeline: lint + unit + fast integration smoke tests
- Main pipeline: all above + full integration suite
- Nightly pipeline: long-running regression + security deep scan

---

## 10) Security in CI pipelines

### Secrets handling
- Store credentials in Jenkins Credentials / GitHub Secrets.
- Never hardcode tokens in repository.
- Avoid echoing secrets in logs.

### Supply-chain controls
- SCA dependency scanning
- Container scanning
- Artifact signing (e.g., Cosign)
- SBOM generation (CycloneDX/SPDX)

### Principle of least privilege
- CI should have only required permissions.
- Separate read-only vs publish credentials.

---

## 11) Performance optimization in CI

1. Parallelize independent stages.
2. Cache dependencies.
3. Reuse toolchain images/agents.
4. Avoid unnecessary full rebuilds.
5. Minimize artifact size and number.

### Example parallel concept (Jenkins)
```groovy
stage('Test Matrix') {
  parallel {
    stage('Unit Tests') {
      steps { sh 'mvn -q test' }
    }
    stage('Static Analysis') {
      steps { sh 'mvn -q -DskipTests=true spotbugs:check || true' }
    }
  }
}
```

---

## 12) CI observability and metrics

Track these key CI metrics:
- pipeline duration (P50/P95)
- failure rate
- flaky test rate
- queue/wait time
- time-to-feedback
- success rate after retry

Alert examples:
- Failure rate > 20% for 30 min
- Median build time increase > 40%
- Main-branch CI broken for > 15 min

---

## 13) Common CI anti-patterns

1. Long-lived branches with huge merges
2. Rebuilding per environment
3. Using mutable `latest` tag only
4. Running everything on CI controller node
5. Missing test reports/artifacts
6. No retention policy (logs/artifacts explode)
7. Shared mutable workspaces causing collisions
8. Manual undocumented hotfixes bypassing CI

---

## 14) Troubleshooting quick runbook

When a CI build fails:
1. Identify first failing stage.
2. Reproduce locally with same commands.
3. Check dependency or network transient failures.
4. Verify toolchain versions and lockfiles.
5. Inspect test reports and stack traces.
6. Re-run once if suspected flaky infrastructure.
7. Open fix PR quickly; keep main green.

Useful patterns:
```bash
# Maven
mvn --batch-mode -e -X test

# Docker
docker build --no-cache -t debug-image .

# Node
npm ci && npm test
```

---

## 15) CI governance checklist

- [ ] Jenkinsfile/workflow stored in Git
- [ ] Branch protection requires CI checks
- [ ] Build/test/security gates defined
- [ ] Immutable artifact/version strategy used
- [ ] Secrets managed by CI platform, not code
- [ ] Build retention policy enabled
- [ ] Parallelization/caching strategy documented
- [ ] Incident/runbook for pipeline failures
- [ ] Weekly flaky-test review
- [ ] Quarterly pipeline security review

---

## 16) Practical “golden pipeline” template

A good default CI pipeline should:
1. checkout code
2. install deps deterministically
3. lint + static checks
4. run unit tests
5. package artifact
6. scan dependencies/image
7. publish reports/artifacts
8. optionally publish container image

All with:
- immutable versioning
- least privilege credentials
- deterministic and auditable logs

---

## 17) Suggested additions in this Module 8 folder

Add reusable helpers:
- `ci/run-maven-ci.sh`
- `ci/build-image.sh`
- `ci/scan-image.sh`
- `ci/version.sh`
- `ci/README.md` describing expected env vars and outputs

This improves reproducibility and recruiter-readability.

---

## References

- Jenkins Pipeline docs: https://www.jenkins.io/doc/book/pipeline/
- Jenkins Shared Libraries: https://www.jenkins.io/doc/book/pipeline/shared-libraries/
- GitHub Actions docs: https://docs.github.com/actions
- Trunk-based development: https://trunkbaseddevelopment.com/
- SemVer: https://semver.org/
