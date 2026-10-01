
# Complete CI/CD Pipeline with Docker Compose, Jenkins, and Dynamic Versioning

## Overview

This starter project demonstrates a safe, small CI/CD workflow for a containerised Python HTTP service. Docker Compose provides a repeatable local environment, while the `Jenkinsfile` defines the automated validation, test, version, image-build, and optional publishing stages.

It is deliberately a **scaffold**: image publishing and cloud deployment have clear placeholders for you to complete with your own registry and AWS target.

## What Is Included

| Component | Purpose |
| --- | --- |
| `src/app.py` | Minimal HTTP service with `/` and `/health` endpoints. |
| `tests/test_app.py` | Unit tests that run without third-party Python packages. |
| `Dockerfile` | Builds a small non-root Python container image. |
| `docker-compose.yml` | Builds and runs the service locally with a health check. |
| `scripts/version.sh` | Emits a Semantic Versioning-compatible build tag. |
| `scripts/build.sh` | Builds the Compose image with a supplied tag. |
| `scripts/deploy.sh` | Tags and pushes a built image; deployment is intentionally left for you. |
| `Jenkinsfile` | Declarative Jenkins pipeline for the complete CI workflow. |

## Prerequisites

- Docker Desktop or Docker Engine with Docker Compose v2
- Python 3.10 or later
- Jenkins with Git, Pipeline, Credentials Binding, and Docker access on its build agent
- A Git repository for Jenkins to clone
- Optional for publishing: a container registry and credentials stored in Jenkins

## Run Locally

The committed `.env.example` shows the available configuration. The local `.env` file contains safe defaults and is ignored by Git.

1. Run the tests:

	```sh
	python3 -m unittest discover -s tests -v
	```

2. Start the service:

	```sh
	docker compose up --build
	```

3. In a second terminal, check the health endpoint:

	```sh
	curl http://localhost:8080/health
	```

4. Stop the local stack:

	```sh
	docker compose down
	```

## Versioning Strategy

`scripts/version.sh` uses a configurable base version and emits an immutable build tag:

- Local execution: `0.1.0-local`
- Jenkins build 42: `0.1.0-ci.42`

Set `BASE_VERSION` when you want to start the next release line. Keep the base version in `MAJOR.MINOR.PATCH` format. Semantic Versioning uses a major version for incompatible changes, a minor version for backward-compatible features, and a patch version for backward-compatible bug fixes.

## Jenkins Pipeline

Create a **Pipeline** or **Multibranch Pipeline** job that points to this repository and uses the root `Jenkinsfile`.

The pipeline stages are:

1. **Validate** — checks Python syntax and validates the Compose configuration.
2. **Test** — runs the Python unit tests.
3. **Version** — generates a SemVer-compatible image tag using Jenkins' build number.
4. **Build image** — builds `cicd-starter:<generated-tag>` with Docker Compose.
5. **Publish image** — runs only on the `main` branch when `PUBLISH_IMAGE` is selected.

### Enable Image Publishing

Publishing is disabled by default. Before enabling it, update these values in `Jenkinsfile`:

```groovy
IMAGE_NAME = 'your-registry-namespace/cicd-starter'
REGISTRY_HOST = 'your-registry-host'
```

For Amazon ECR, the registry host typically has this form:

```text
<aws-account-id>.dkr.ecr.<aws-region>.amazonaws.com
```

Then add a Jenkins **Username with password** credential with the ID:

```text
container-registry-credentials
```

For ECR, provide short-lived credentials through an AWS-aware Jenkins configuration or adapt the publish stage to use `aws ecr get-login-password`. Never put registry passwords, AWS keys, or tokens in `.env`, `Jenkinsfile`, or Git.

### Add Your Deployment Step

`scripts/deploy.sh` currently stops after successfully pushing the image. Add your deployment action after the push, for example:

- update an Amazon ECS service with the new task-definition image;
- update a Helm values image tag and deploy to Amazon EKS; or
- trigger an approved deployment workflow for your chosen environment.

Keep deployment credentials in Jenkins Credentials and require an appropriate approval or protected-branch policy for production.

## Project Structure

```text
.
├── .env.example
├── Dockerfile
├── Jenkinsfile
├── docker-compose.yml
├── scripts/
│   ├── build.sh
│   ├── deploy.sh
│   └── version.sh
├── src/
│   └── app.py
└── tests/
	 └── test_app.py
```

## Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Semantic Versioning](https://semver.org/)
- [AWS Continuous Integration Overview](https://aws.amazon.com/devops/continuous-integration/)
