
# CD: Deploy Application with Jenkins Pipeline to EC2 Instance (Automatically with Docker Compose)

## Overview
This module builds on the single-container Docker deployment by using **Docker Compose** on the EC2 instance to manage the application. Instead of running a bare `docker run` command via SSH, Jenkins SSHes into the EC2 instance, copies a `docker-compose.yaml` file, and runs `docker-compose up` to start or recreate the service. This approach is more scalable and easier to manage when multiple services are involved.

## How This Differs from the Plain Docker Version
| | Docker (previous module) | Docker Compose (this module) |
|---|---|---|
| Deploy command | `docker run ...` | `docker-compose up -d` |
| Config location | Inline in Jenkinsfile | `docker-compose.yaml` copied to EC2 |
| Multi-service support | Manual | Built-in |
| Rolling updates | Manual stop/rm/run | `docker-compose up --force-recreate` |

## Architecture
```
Developer Push
     │
     ▼
GitHub Repository
     │  (webhook)
     ▼
Jenkins Server (local)
     │  1. Clone repo
     │  2. mvn clean package
     │  3. docker build & push → Docker Hub
     │  4. scp docker-compose.yaml → EC2
     ▼
EC2 Instance
     │  5. docker-compose pull
     │  6. docker-compose up -d --force-recreate
     ▼
Running Application (port 8090)
```

## Prerequisites
- AWS account with EC2 access
- Jenkins server running (locally via `docker-compose up -d jenkins`)
- Docker Hub account and access token
- Git repository containing application code
- Java 21 + Maven available on the Jenkins agent

---

## Step 1: Launch and Configure the EC2 Instance

1. **Launch an EC2 instance** in the AWS console:
   - AMI: **Ubuntu 24.04 LTS**
   - Instance type: `t2.micro` (free tier) or larger
   - Storage: 20 GB minimum

2. **Configure the Security Group** — open inbound rules:
   | Port | Protocol | Source | Purpose |
   |------|----------|--------|---------|
   | 22   | TCP      | Your IP / Jenkins IP | SSH + SCP access |
   | 8090 | TCP      | 0.0.0.0/0 | Application access |

3. **Create or select a Key Pair** (`.pem` file). Save it securely.

4. **SSH into the instance** and install Docker + Docker Compose:
   ```bash
   ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

   sudo apt-get update
   sudo apt-get install -y docker.io docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker

   # Allow ubuntu user to run Docker without sudo
   sudo usermod -aG docker ubuntu
   newgrp docker
   ```

5. **Verify both tools are available:**
   ```bash
   docker --version
   docker-compose --version
   ```

---

## Step 2: Set Up Docker Hub

1. Log in to [hub.docker.com](https://hub.docker.com) and create a repository, e.g. `your-username/myapp`.
2. Create an **access token** (Account Settings → Security → New Access Token).

---

## Step 3: Configure Jenkins

### 3.1 Start Jenkins Locally
```bash
docker-compose up -d jenkins
```
Access Jenkins at `http://localhost:8080`. Complete the setup wizard and install:
- **Pipeline**
- **Git**
- **SSH Agent**
- **Docker Pipeline**
- **Credentials Binding**

### 3.2 Add Credentials to Jenkins
Navigate to **Manage Jenkins → Credentials → (global) → Add Credentials**.

| ID | Kind | Value |
|----|------|-------|
| `dockerhub-credentials` | Username with password | Docker Hub username + access token |
| `ec2-ssh-key` | SSH Username with private key | Username: `ubuntu`, Key: paste your `.pem` content |

### 3.3 Create the Pipeline Job
1. Click **New Item** → name it `myapp-cd-compose` → select **Pipeline** → OK.
2. Under **Build Triggers**, check **GitHub hook trigger for GITScm polling**.
3. Under **Pipeline**, select **Pipeline script from SCM**:
   - SCM: Git
   - Repository URL: your GitHub repo URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Save.

---

## Step 4: Prepare the EC2 docker-compose.yaml

Create a separate `docker-compose.yaml` file in your repository root that will be **copied to and executed on the EC2 instance**. This is different from the local one that runs Jenkins:

```yaml
# ec2-docker-compose.yaml  ← commit this to your repo root
version: '3.8'

services:
  myapp:
    image: your-dockerhub-username/myapp:latest
    container_name: myapp
    ports:
      - "8090:8080"
    restart: unless-stopped
```

> Note: On the EC2 instance there is no need for the `jenkins` or `docker:dind` services — those are only for local development.

---

## Step 5: Create the Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = "your-dockerhub-username/myapp"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"
        EC2_HOST   = "ubuntu@<EC2_PUBLIC_IP>"
        COMPOSE_FILE = "ec2-docker-compose.yaml"
    }

    stages {
        stage('Build JAR') {
            steps {
                dir('myapp') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ./myapp
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Copy Compose File to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh "scp -o StrictHostKeyChecking=no ${COMPOSE_FILE} ${EC2_HOST}:/home/ubuntu/docker-compose.yaml"
                }
            }
        }

        stage('Deploy with Docker Compose on EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_HOST} '
                            docker-compose pull &&
                            docker-compose up -d --force-recreate
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Deployment successful! App running at http://<EC2_PUBLIC_IP>:8090"
        }
        failure {
            echo "Pipeline failed. Check the logs above."
        }
    }
}
```

---

## Step 6: Configure the GitHub Webhook

1. In your GitHub repository go to **Settings → Webhooks → Add webhook**.
2. Set **Payload URL** to `http://<JENKINS_URL>:8080/github-webhook/`.
3. Set **Content type** to `application/json`.
4. Select **Just the push event**.
5. Click **Add webhook**.

> If Jenkins is running locally, expose it with [ngrok](https://ngrok.com/): `ngrok http 8080`.

---

## Step 7: Test the Full Pipeline

1. Push a change to the `main` branch.
2. Watch the Jenkins job trigger and complete.
3. Verify the running container on EC2:
   ```bash
   ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>
   docker-compose ps
   # myapp should show as "Up"
   ```
4. Test the application endpoints:
   ```bash
   curl http://<EC2_PUBLIC_IP>:8090/
   # Expected: Hello from MyApp! The application is running successfully.

   curl http://<EC2_PUBLIC_IP>:8090/health
   # Expected: OK
   ```

---

## Project File Structure
```
.
├── Jenkinsfile                     ← Pipeline definition
├── docker-compose.yaml             ← Local: runs Jenkins + Docker-in-Docker
├── ec2-docker-compose.yaml         ← Remote: copied to EC2 for app deployment
├── Dockerfile                      ← Root-level build (used by Jenkins)
└── myapp/
    ├── Dockerfile                  ← Multi-stage build (Maven → runtime image)
    ├── pom.xml
    └── src/main/java/com/example/myapp/
        ├── Application.java
        └── HelloController.java
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `docker-compose: command not found` on EC2 | Run `sudo apt-get install -y docker-compose` on the instance |
| `scp` fails in Jenkins | Ensure `ec2-ssh-key` credential is correctly set and port 22 is open |
| Container exits immediately | Check logs: `ssh ubuntu@<EC2_IP> 'docker logs myapp'` |
| Old image still running after deploy | Confirm `--force-recreate` is in the compose command and the image was pushed |
| Port 8090 not reachable | Check EC2 Security Group inbound rules allow TCP 8090 from `0.0.0.0/0` |
| GitHub webhook not firing | Use ngrok for local Jenkins; check webhook delivery status in GitHub Settings |

---

## References
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EC2 Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [Spring Boot Docs](https://docs.spring.io/spring-boot/docs/current/reference/html/)
