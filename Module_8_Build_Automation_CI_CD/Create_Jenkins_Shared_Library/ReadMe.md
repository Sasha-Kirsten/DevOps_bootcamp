
# Create Jenkins Shared Library

## Project summary

This module demonstrates a reusable Jenkins Shared Library for a Maven-based application pipeline. The library centralizes Maven verification, Docker image creation, controlled registry publishing, and approval-gated Kubernetes manifest deployment.

**Technologies:** Jenkins, Groovy, Maven, Docker, Kubernetes, Git

The consumer `Jenkinsfile` is deliberately safe by default: it tests and builds an image locally, but does not publish an image or change a Kubernetes cluster unless a user explicitly enables those actions.

## Repository layout

```text
.
├── Jenkinsfile          # Example consumer pipeline
├── Main.groovy           # Deprecated migration marker; contains no executable steps
└── vars/
	└── ciSteps.groovy   # Global shared-library variable: ciSteps
```

Jenkins exposes a file in `vars/` as a global Pipeline variable. Therefore, `vars/ciSteps.groovy` is used from a Jenkinsfile as `ciSteps.mavenVerify(...)`, `ciSteps.buildImage(...)`, and so on.

## Reusable steps

| Step | Purpose |
| --- | --- |
| `ciSteps.mavenVerify(directory)` | Runs `mvn --batch-mode clean verify`. |
| `ciSteps.buildImage(directory, repository, tag)` | Builds a Docker image from the application directory. |
| `ciSteps.publishImage(source, tag, target, credentialId)` | Logs in using Jenkins credentials, tags, and pushes an image. |
| `ciSteps.deployManifest(path)` | Applies a Kubernetes manifest with `kubectl`. |

## Configure Jenkins

1. In Jenkins, open **Manage Jenkins → System → Global Pipeline Libraries**.
2. Add a library named `bootcamp-shared-library` that points to this repository.
3. Configure `main` as the default version, or update the annotation in the consumer pipeline to your chosen branch or tag.
4. Configure the application pipeline to load the library:

   ```groovy
   @Library('bootcamp-shared-library@main') _
   ```

Use a trusted global library only when repository contributors are trusted: shared-library code executes as part of the Jenkins pipeline and can access Jenkins capabilities.

## Run the consumer pipeline

The consumer `Jenkinsfile` belongs with an application repository (or in a workspace that contains one). That application must contain:

- a `pom.xml` for Maven verification;
- a `Dockerfile` in `APPLICATION_DIRECTORY`;
- a Jenkins agent with Maven and Docker available;
- `kubectl` plus an authorized cluster context only when deployment is enabled.

Pipeline parameters:

| Parameter | Default | Description |
| --- | --- | --- |
| `APPLICATION_DIRECTORY` | `.` | Directory containing the Maven project and Dockerfile. |
| `IMAGE_REPOSITORY` | empty | Fully qualified registry repository, for example `docker.io/your-user/myapp`. |
| `IMAGE_TAG` | Jenkins build number | Immutable tag to publish; leave empty to use the build number. |
| `KUBERNETES_MANIFEST` | empty | Manifest path to apply after approval. |
| `PUBLISH_IMAGE` | `false` | Enables registry publication. |
| `DEPLOY_TO_KUBERNETES` | `false` | Enables publication, manual approval, and Kubernetes deployment. |

The pipeline uses `local-build:<tag>` for its local Docker image. Set `PUBLISH_IMAGE=true` and provide `IMAGE_REPOSITORY` to publish it. Use a fully qualified repository name: the shared step treats the first path segment as the registry host for `docker login`.

To deploy, set `DEPLOY_TO_KUBERNETES=true`, provide both `IMAGE_REPOSITORY` and `KUBERNETES_MANIFEST`, then approve the explicit Jenkins prompt. Ensure the manifest already references the intended immutable image tag; this example applies the supplied manifest without modifying it.

## Credentials and safety controls

Create a Jenkins **Username with password** credential with the ID:

```text
container-registry-credentials
```

The registry password is supplied to `docker login` through standard input and is never stored in this repository. The pipeline also:

- disables concurrent builds to reduce image/deployment collisions;
- avoids mutable `latest` tags;
- keeps publishing and deployment opt-in;
- requires approval before `kubectl apply`;
- avoids repository mutation commands such as `git commit` and `git push`.

## Validation scope

This repository contains pipeline/library code, not a Maven application, Dockerfile, Kubernetes manifest, Jenkins controller, or registry credentials. Static validation can verify the layout, expected shared-library methods, safe defaults, and absence of known unsafe patterns. A full Jenkins run requires an application repository and a configured Jenkins environment; it should be performed only against non-production registry and cluster targets first.

## Recruiter walkthrough

1. Show `vars/ciSteps.groovy` and explain the `vars/` global-variable convention.
2. Open `Jenkinsfile` to show consumption through `@Library(...)` and `ciSteps.*`.
3. Point out that Maven verification occurs before image construction.
4. Show the default-disabled publication/deployment flags and the manual deployment approval.
5. Explain that credentials are managed in Jenkins rather than committed to source control.

## References

- [Jenkins Shared Libraries](https://www.jenkins.io/doc/book/pipeline/shared-libraries/)
- [Jenkins Pipeline syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
