# Complete CI/CD with Terraform

## Demo project

**Demo Project:** Complete CI/CD with Terraform  
**Technologies Used:** Jenkins, Maven, Docker, Docker Compose, Terraform, AWS EC2, Linux, Git  
**Project Description:** Build and publish an immutable Java container image, provision its EC2 host with Terraform, and deploy the reviewed image through a gated Jenkins pipeline.

This is a recruiter-ready **CI/CD infrastructure template**. The project provides a valid Terraform EC2 stack, container deployment configuration, host bootstrap script, and Jenkins declarative pipeline. It is intentionally safe by default: formatting and Terraform validation run automatically, while Maven builds, image pushes, AWS plans, Terraform applies, and SSH deployments require explicit Jenkins parameters.

> **Verification scope:** The Terraform and deployment artifacts can be tested locally without AWS. The repository does not include a Java application or `pom.xml`, so a Maven build and Docker image build require an application repository or subdirectory supplied through the `APPLICATION_DIRECTORY` Jenkins parameter.

## Deployment flow

```text
Git commit → Jenkins validation → Maven tests → immutable Docker image → registry
														   ↓
									  reviewed Terraform plan → approval → EC2 deployment
```

The project combines these tools:

| Tool | Responsibility |
| --- | --- |
| Git | Stores the application, pipeline, Docker, and Terraform configuration. |
| Jenkins | Orchestrates build, test, image publication, infrastructure provisioning, and deployment. |
| Maven | Builds and tests the Java application JAR file. |
| Docker | Packages the application and runs it as a container. |
| Docker Compose | Defines the application services deployed to the EC2 host. |
| Terraform | Creates and maintains AWS infrastructure. |
| AWS EC2 | Runs the deployed application. |

> **Learning project:** The source is validated locally. Connect it to AWS and Jenkins only after completing the environment-specific cloud-deployment checklist below.

## Target Deployment Flow

```text
Developer pushes code to Git
		  │
		  ▼
	  Jenkins pipeline
		  │
		  ├── 1. Build and test Java application with Maven
		  ├── 2. Build Docker image from the JAR file
		  ├── 3. Push a versioned image to a registry
		  ├── 4. Run Terraform plan and apply for EC2 infrastructure
		  └── 5. Connect to EC2 and deploy with Docker Compose
							   │
							   ▼
					Application container on EC2
```

The pipeline should publish an immutable image tag, such as a Git commit SHA or build number. Avoid relying only on `latest`, because it is difficult to identify exactly what version is running.

## Repository Contents

| File | Intended purpose |
| --- | --- |
| `jenkinsfile` | Valid declarative Jenkins pipeline. Configure the job with this script path, or rename it to `Jenkinsfile` before use. |
| `main.tf` | VPC, public subnet, internet route, security group, and EC2 application host. |
| `provider.tf` | Terraform/AWS provider requirements and standard tags. |
| `variable.tf` | Typed input variables for the AWS environment and secure ingress. |
| `outputs.tf` | EC2 public IP and application URL for the deployment stage. |
| `Dockerfile` | Packages a built Java JAR using Eclipse Temurin 17. |
| `docker-compose.yaml` | Target-host Compose file that runs the exact immutable image selected by CI. |
| `server-cmds.sh` | Amazon Linux 2023 Docker bootstrap run through EC2 user data. |
| `terraform.tfvars.example` | Non-secret Terraform input template. |

## Prerequisites

Prepare the following before configuring Jenkins:

- A Git repository containing the Java Maven application and its `pom.xml`.
- An AWS account and a least-privilege IAM role or user for the learning environment.
- Terraform installed in the Jenkins execution environment.
- Docker available to the Jenkins agent that builds and pushes images.
- A Docker Hub or other container-registry account, repository, and Jenkins credential.
- An EC2 key pair, with its private key stored as a Jenkins SSH credential.
- An EC2 security group that permits only the application ports and restricted administrative access required for the project.
- Jenkins plugins or agent capabilities for Pipeline, Git, Credentials Binding, SSH Agent, Maven, Terraform, and Docker operations.

Do not save AWS access keys, Docker passwords, SSH private keys, or application secrets in the repository. Store them as Jenkins credentials or use short-lived workload identities.

## Setup Steps

### 1. Create an SSH key pair for the EC2 host

The pipeline needs a secure way to connect to the provisioned EC2 instance for deployment. Create an EC2 key pair in the same AWS Region as the instance, then store the private key in Jenkins as an SSH private-key credential.

Use a dedicated deployment key rather than a personal key. Restrict SSH access in the EC2 security group to the Jenkins agent's known network address, a bastion host, or a private network. For production, prefer AWS Systems Manager Session Manager instead of exposing SSH.

### 2. Make Terraform available to Jenkins

Terraform must be available in the Jenkins agent that executes the provisioning stage. Common approaches are:

- Install a pinned Terraform version on a dedicated Jenkins agent.
- Use a custom Jenkins agent image that already contains Terraform, the AWS CLI, Docker tooling, and any required build tools.
- Run the Terraform stage in a dedicated Terraform container image.

Verify the tool is available before provisioning:

```bash
terraform version
terraform init
terraform validate
```

Pin the Terraform and AWS provider versions so a new release cannot unexpectedly change a pipeline run.

### 3. Store application and infrastructure configuration in Git

Keep the application source, `Dockerfile`, Compose configuration, `Jenkinsfile`, and Terraform code in Git. This gives the team one reviewable history of application and infrastructure changes.

Terraform configuration files describe the desired infrastructure; the Terraform **state file** records the current managed resources. Do not commit `terraform.tfstate` to Git. For shared use, configure an encrypted, versioned, locked remote state backend such as a private S3 bucket.

Add at least these entries to `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
*.pem
```

### 4. Configure Jenkins credentials

Create credentials in Jenkins and refer to them by credential ID. The pipeline uses the following IDs:

| Credential ID | Recommended type | Purpose |
| --- | --- | --- |
| `container-registry-credentials` | Username with password | Authenticates Docker image publication without exposing the password in arguments. |
| `aws-terraform-deployer` | AWS Credentials | Performs the opt-in Terraform plan and apply stages. Prefer a least-privilege assumed role. |
| `jenkins-ec2-deployer` | SSH username with private key | Connects to the EC2 deployment host after approval. |

Use a dedicated AWS IAM role for the pipeline with only the permissions needed to manage the intended Terraform resources and read/write the remote state. Never print credentials in build logs.

### 5. Implement the CI stages

The continuous integration part should run on every pull request or branch push:

1. **Checkout:** Retrieve the application and infrastructure source from Git.
2. **Build and test:** Run `mvn clean package` and fail the job if compilation or tests fail.
3. **Build image:** Build the Docker image only after a successful Maven build. The supplied `Dockerfile` copies the JAR from `target/`.
4. **Scan image (recommended):** Check dependencies and the container image for known vulnerabilities.
5. **Push image:** Log in through Jenkins credentials and push an immutable, versioned image tag to the selected registry.

Publish test results and archive the generated JAR as a Jenkins artifact when appropriate. This makes failures easier to diagnose and supports traceability.

### 6. Provision the EC2 infrastructure with Terraform

Run these Terraform checks before any apply:

```bash
terraform fmt -check
terraform init
terraform validate
terraform plan -out=tfplan
```

Review the generated plan. The deployment stage should apply that exact approved plan:

```bash
terraform apply tfplan
```

For production environments, require an approval after the plan is reviewed. Ensure only one deployment job can apply to a particular Terraform state at a time.

### 7. Deploy the Docker image to EC2

After Terraform finishes, retrieve the EC2 public IP address from a declared Terraform output. Wait for host bootstrapping to finish, copy only the necessary Compose and deployment files, and deploy the image.

The target host should:

1. Install and enable Docker during EC2 bootstrap.
2. Authenticate to the private registry if required.
3. Pull the exact image tag built by the pipeline.
4. Run `docker compose up -d` with that image tag.
5. Perform an application health check.
6. Report the deployed version and endpoint in the Jenkins build log.

Avoid disabling SSH host-key verification (`StrictHostKeyChecking=no`) in a production pipeline. Use a managed `known_hosts` file or a controlled initial host-key verification process instead.

## Before running a cloud deployment

Static checks are suitable for every pull request. A real plan/apply/deployment requires an AWS development account, a valid Amazon Linux 2023 AMI for the selected Region, an existing key pair (or an SSM-based alternative), a registry repository, and a Java application directory containing `pom.xml` and the `target/` JAR expected by the Dockerfile.

Before enabling the opt-in Jenkins parameters, complete the environment-specific tasks below:

- [ ] Configure the Jenkins job script path for `jenkinsfile`, or rename the file to `Jenkinsfile` in the repository before creating the job.
- [ ] Create Jenkins credentials: `container-registry-credentials`, `aws-terraform-deployer`, and `jenkins-ec2-deployer`.
- [ ] Configure a remote Terraform backend before multiple users or jobs manage the same environment.
- [ ] Replace the example AMI, key pair name, and trusted SSH CIDR in `terraform.tfvars`.
- [ ] Restrict the application ingress CIDR or put the service behind an HTTPS load balancer for production.
- [ ] Verify the actual application health endpoint after `docker compose up -d`; the generic template cannot infer it.
- [ ] Record an image digest and test a rollback by redeploying a previous immutable image tag.

## Recommended Pipeline Stages

| Stage | Primary action | Required result |
| --- | --- | --- |
| Validate | Format and validate Terraform; compile and test the application. | No configuration, build, or test errors. |
| Build | Create the Java JAR and Docker image. | A reproducible, versioned image. |
| Publish | Push the image to the registry. | Image digest and tag recorded in the build. |
| Plan | Create Terraform plan. | Reviewed, expected infrastructure changes. |
| Approve | Manual gate for protected environments. | Authorised release decision. |
| Provision | Apply the approved Terraform plan. | EC2 host and network are ready. |
| Deploy | Pull and run the exact image version on EC2. | Application service starts successfully. |
| Verify | Run endpoint, container, and log checks. | Healthy application and recorded deployment result. |

## Security and Operations Checklist

- [ ] Use remote Terraform state with encryption, versioning, and locking.
- [ ] Use least-privilege IAM roles and short-lived credentials where possible.
- [ ] Keep Jenkins credentials and application secrets out of source control and logs.
- [ ] Restrict EC2 inbound security-group rules; do not allow unrestricted SSH.
- [ ] Pin base-image, Terraform, provider, and dependency versions.
- [ ] Use image scanning and dependency checks in CI.
- [ ] Tag images and infrastructure with the application, environment, source revision, and owner.
- [ ] Monitor EC2, container logs, application health, and AWS costs.
- [ ] Keep a documented rollback method, such as redeploying the previous immutable image tag.
- [ ] Destroy unused learning environments to avoid EC2, Elastic IP, storage, and network charges.

## Getting Started

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and set approved development-account values.
2. Configure Jenkins agents, credentials, and repository access.
3. Test the Maven build and Docker image locally or on a dedicated CI agent.
4. Validate Terraform and review a plan in a non-production AWS environment.
5. Run the pipeline with a versioned image tag and verify the deployed application endpoint.
6. Add approvals, remote state, scanning, health checks, and rollback before using the process for production.

## Resources

- [Terraform AWS provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform S3 bucket resource documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- [Terraform language documentation](https://developer.hashicorp.com/terraform/language)
- [AWS EC2 documentation](https://docs.aws.amazon.com/ec2/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Jenkins Pipeline documentation](https://www.jenkins.io/doc/book/pipeline/)

## Topics to Add Later

- A corrected production-ready `Jenkinsfile`
- A corrected EC2 Terraform configuration with secure remote state
- A separate Compose file for the EC2 deployment target
- Automated integration, image-security, and infrastructure-security scans
- Blue/green or rolling deployment strategy
- Automated rollback and incident-response steps
- HTTPS, reverse proxy, DNS, and certificate management