
# Dynamically Version a Java Application in a Jenkins Pipeline

## Demo project

**Demo Project:** Dynamic Application Versioning with Jenkins  
**Technologies Used:** Java 21, Maven, JUnit 5, Docker, Jenkins, Groovy, Bash, Git  
**Project Description:** Validate a Java application, generate an immutable Semantic Versioning-compatible CI image tag, build a container image, and optionally publish the tested image through Jenkins.

## Overview

This project demonstrates a safe Continuous Integration workflow for a Java application. The tracked `VERSION` file provides the release baseline; Jenkins combines it with the Jenkins build number to create a unique image tag without modifying or committing source files during a build.

For example, `VERSION` set to `1.0.0` and Jenkins build `42` produces:

```text
1.0.0-ci.42
```

The `-ci.42` pre-release identifier is SemVer-compatible and provides traceability without relying on the mutable `latest` tag.

## Verification status

The following local checks have passed:

- `mvn --batch-mode clean verify`
- One JUnit 5 unit test for the application greeting
- Java 21 compilation with a pinned Maven compiler plugin
- Packaged JAR smoke test, which prints `Hello, Maven!`

The Docker image build requires Docker Desktop or Docker Engine. It was attempted but could not start because the local Docker daemon is unavailable. No image was pushed and no credentials were used.

## Project contents

| File | Purpose |
| --- | --- |
| `VERSION` | Tracked `MAJOR.MINOR.PATCH` release baseline. |
| `CI_step.groovy` | Reusable Jenkins helper functions for version validation, Maven verification, and image build. |
| `Jenkinsfile` | Declarative CI pipeline with opt-in registry publishing. |
| `pom.xml` | Java 21 Maven project with JUnit 5 tests. |
| `Dockerfile` | Java 21 runtime image for the Maven-built JAR. |
| `src/` | Application and unit-test source. |

## Jenkins workflow

The pipeline runs from a monorepo checkout and uses the project directory internally.

| Stage | Behavior |
| --- | --- |
| Checkout | Retrieves the repository. |
| Create Build Version | Reads `VERSION`, unless `BASE_VERSION` is supplied, and validates both the version and Jenkins build number. |
| Build and Test | Runs `mvn --batch-mode clean verify`. |
| Build Image | Builds `simple-maven-app:<build-version>` with a Docker image label. |
| Publish Image | Runs only when `PUBLISH_IMAGE` is explicitly selected. |

Publishing requires these Jenkins parameters and credentials:

- `IMAGE_REPOSITORY`, such as `docker.io/your-user/simple-maven-app`
- `REGISTRY_HOST`, which defaults to `docker.io`
- `docker-hub-credentials` as a Jenkins **Username with password** credential

The pipeline uses `--password-stdin`, does not mutate Git, disables concurrent builds, archives JAR artifacts, and publishes test reports. Use a protected branch and least-privilege registry token before enabling publication.

## Run locally

```text
mvn --batch-mode clean verify
java -cp target/simple-maven-app-1.0-SNAPSHOT.jar com.example.App
```

With Docker running, build the local image:

```text
docker build --build-arg APP_VERSION=1.0.0-local --tag simple-maven-app:1.0.0-local .
```

## Recruiter walkthrough

1. Start with `VERSION` and explain the separation between a human-controlled release baseline and Jenkins’ immutable build identifier.
2. Show `CI_step.groovy`, which rejects invalid versions rather than silently generating malformed tags.
3. Show the unit test and the successful Maven verification output.
4. Walk through the Jenkins publish opt-in, credentials binding, artifact archive, and test-report publication.
5. Explain that a live demo should show the Jenkins build number, exact image tag/digest, and registry evidence—without revealing credentials.
