
# Deploy a Web Application to an EC2 Instance Manually

## Overview

This starter project demonstrates a manual deployment workflow for a small web application on Amazon EC2. The application is a static site served by an unprivileged NGINX container. Replace the example page with your own application as you progress through the exercise.

The workflow is intentionally manual:

1. Build an image locally or in your CI pipeline.
2. Push the immutable image to a registry.
3. Connect to EC2 and pull that exact image.
4. Run it with Docker Compose and verify its health endpoint.

## Project Files

| File | Purpose |
| --- | --- |
| `index.html`, `styles.css` | Sample website content to replace with your application. |
| `nginx.conf` | NGINX configuration; serves the site on container port `8080`. |
| `Dockerfile` | Creates the web-server image using a non-root NGINX image. |
| `docker-compose.yml` | Starts the web service and maps host port `80` to container port `8080`. |
| `scripts/bootstrap-ec2.sh` | Installs and enables Docker on Ubuntu, Debian, or Amazon Linux. |
| `scripts/deploy.sh` | Pulls and starts an image using a repository and immutable tag. |
| `scripts/verify.sh` | Checks container status and the local health endpoint. |

## Prerequisites

- An AWS account and permissions to create EC2, security-group, and key-pair resources.
- An Ubuntu, Debian, or Amazon Linux EC2 instance.
- Docker and Docker Compose locally if you want to test the image before deploying.
- A container registry if you deploy a pre-built image. This can be Amazon ECR, Docker Hub, or another registry.

> **Access key vs SSH key pair:** An IAM access key is for AWS API/CLI authentication; it is **not** the private key used to connect to EC2. Create an EC2 key pair for SSH, or use AWS Systems Manager Session Manager with an instance role to avoid opening SSH access.

## 1. Launch and Secure the Instance

For a learning environment, select a small supported Linux AMI and an appropriate instance type. Configure its security group with the smallest access required:

- **HTTP (TCP 80):** allow only the clients that must reach the application. Use `0.0.0.0/0` only for a short-lived public demonstration.
- **HTTPS (TCP 443):** add when you configure TLS.
- **SSH (TCP 22):** restrict to your current public IP address, or prefer Session Manager.

Do not use the root AWS account for normal work. Use IAM identities and least-privilege permissions.

## 2. Connect to EC2

Store the downloaded EC2 key pair safely outside the repository and restrict its permissions on your local computer:

```sh
chmod 400 ~/.ssh/your-ec2-key.pem
ssh -i ~/.ssh/your-ec2-key.pem ec2-user@<public-ip-or-dns>
```

The default user differs by image: Amazon Linux commonly uses `ec2-user`; Ubuntu commonly uses `ubuntu`.

## 3. Install Docker on the Instance

Copy this project to the instance with Git or SCP, then run the bootstrap script from the project directory:

```sh
chmod +x scripts/*.sh
./scripts/bootstrap-ec2.sh
```

Sign out and reconnect after it completes. Confirm the Docker client and Compose plugin are available:

```sh
docker version
docker compose version
```

If the script reports that Compose is unavailable on your AMI, install the Docker Compose plugin following the Docker documentation for that distribution.

## 4. Test the Application Locally

Before deploying to AWS, test the application on your machine:

```sh
docker compose up --build
```

Open `http://localhost:8080` and verify:

```sh
curl http://localhost:8080/health
```

Stop the local service when finished:

```sh
docker compose down
```

## 5. Build and Publish an Image

Choose a real registry path and an immutable version such as `1.0.0` or a Git commit SHA. Do not publish only `latest` for a deployment you may need to reproduce or roll back.

```sh
docker build -t <registry>/<namespace>/ec2-web-starter:1.0.0 .
docker push <registry>/<namespace>/ec2-web-starter:1.0.0
```

For private registries, authenticate on the EC2 host using a secure method before deployment. For ECR, prefer an EC2 instance role that permits read access to the specific repository instead of long-lived AWS access keys on the server.

## 6. Deploy the Published Image on EC2

From the project directory on the EC2 instance, run:

```sh
./scripts/deploy.sh <registry>/<namespace>/ec2-web-starter 1.0.0
./scripts/verify.sh
```

The deploy script writes a local `.env` file with the image repository, tag, and host port, pulls the image, starts it with Docker Compose, and waits for the container health check. `.env` is ignored by Git; never place credentials in it.

Visit:

```text
http://<ec2-public-ip-or-dns>/
```

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Browser cannot connect | Confirm the instance is running, the security group permits TCP `80`, and the instance has a public route/IP or load balancer. |
| Container does not start | Run `docker compose ps` and `docker compose logs web`. |
| Health check fails | Run `curl http://localhost/health` on the instance and inspect the container logs. |
| Image pull is denied | Authenticate to the registry or grant the EC2 instance role read access to the required image repository. |
| SSH is denied | Confirm the username, key-pair permissions, security-group source IP, and route to the instance. |

## Next Improvements

- Add HTTPS with a reverse proxy or Application Load Balancer and AWS Certificate Manager.
- Move the manual image build and push into Jenkins.
- Replace direct SSH with AWS Systems Manager Session Manager.
- Add CloudWatch logs, alarms, and an instance role with minimal registry permissions.
- Deploy multiple instances behind a load balancer or migrate the container to ECS/EKS for production workloads.

## Resources

- [Amazon EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Linux Documentation and Man Pages](https://linux.die.net/)
