
# CD: Deploy Application with Jenkins Pipeline to EC2 Instance (Automatically with Docker)

## Overview
This module demonstrates how to set up a continuous deployment (CD) pipeline using Jenkins to automatically build and deploy a Spring Boot application to an AWS EC2 instance using Docker containers. Every push to the main branch triggers Jenkins to build a new Docker image and redeploy it on the EC2 instance without any manual intervention.

## Architecture
```
Developer Push
     │
     ▼
GitHub Repository
     │  (webhook)
     ▼
Jenkins Server (local or remote)
     │  1. Clone repo
     │  2. mvn clean package
     │  3. docker build & push → Docker Hub
     ▼
EC2 Instance
     │  4. docker pull (latest image)
     │  5. docker stop old container
     │  6. docker run new container
     ▼
Running Application (port 8090)
```

## Prerequisites
- AWS account with EC2 access
- Jenkins server installed and running
- Docker Hub account (or another container registry)
- Git repository with application code
- Java 21 and Maven installed on the Jenkins agent (or use the Docker agent in `docker-compose.yaml`)

---

## Step 1: Launch and Configure the EC2 Instance

1. **Launch an EC2 instance** in the AWS console:
   - AMI: **Ubuntu 24.04 LTS**
   - Instance type: `t2.micro` (free tier) or larger
   - Storage: 20 GB minimum

2. **Configure the Security Group** — open inbound rules:
   | Port | Protocol | Source | Purpose |
   |------|----------|--------|---------|
   | 22   | TCP      | Your IP / Jenkins IP | SSH access |
   | 8090 | TCP      | 0.0.0.0/0 | Application access |

3. **Create or select a Key Pair** (`.pem` file). Save it securely — you will need it for Jenkins SSH credentials.

4. **SSH into the instance** and install Docker:
   ```bash
   ssh -i your-key.pem ubuntu@<EC2_PUBLIC_IP>

   sudo apt-get update
   sudo apt-get install -y docker.io
   sudo systemctl start docker
   sudo systemctl enable docker

   # Allow the ubuntu user to run Docker without sudo
   sudo usermod -aG docker ubuntu
   newgrp docker
   ```

5. **Verify Docker is running:**
   ```bash
   docker --version
   ```

---

## Step 2: Set Up Docker Hub

1. Log in to [hub.docker.com](https://hub.docker.com) and create a **public or private repository**, e.g. `your-username/myapp`.
2. Note your Docker Hub **username** and create an **access token** (Account Settings → Security → New Access Token). You will add this to Jenkins credentials.

---

## Step 3: Configure Jenkins

### 3.1 Start Jenkins Locally
From this project directory, start Jenkins using Docker Compose:
```bash
docker-compose up -d jenkins
```
Access Jenkins at `http://localhost:8080`. Complete the initial setup wizard and install the following plugins:
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
| `ec2-ssh-key` | SSH Username with private key | Username: `ubuntu`, Key: paste contents of your `.pem` file |

### 3.3 Create the Pipeline Job
1. Click **New Item** → name it `myapp-cd` → select **Pipeline** → OK.
2. Under **Build Triggers**, check **GitHub hook trigger for GITScm polling**.
3. Under **Pipeline**, select **Pipeline script from SCM**:
   - SCM: Git
   - Repository URL: your GitHub repo URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Save.

---

## Step 4: Create the Jenkinsfile

Create a `Jenkinsfile` in the root of your repository:

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME  = "your-dockerhub-username/myapp"
        IMAGE_TAG   = "${env.BUILD_NUMBER}"
        EC2_HOST    = "ubuntu@<EC2_PUBLIC_IP>"
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

        stage('Deploy to EC2') {
            steps {
                sshagent(['ec2-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${EC2_HOST} '
                            docker pull ${IMAGE_NAME}:latest &&
                            docker stop myapp || true &&
                            docker rm myapp || true &&
                            docker run -d --name myapp -p 8090:8080 ${IMAGE_NAME}:latest
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

## Step 5: Configure the GitHub Webhook

1. In your GitHub repository go to **Settings → Webhooks → Add webhook**.
2. Set **Payload URL** to `http://<JENKINS_URL>:8080/github-webhook/`.
3. Set **Content type** to `application/json`.
4. Select **Just the push event**.
5. Click **Add webhook**.

> If Jenkins is running locally, expose it using [ngrok](https://ngrok.com/): `ngrok http 8080` and use the generated URL as the webhook payload URL.

---

## Step 6: Test the Full Pipeline

1. Push any change to the `main` branch of your repository.
2. Watch the Jenkins job trigger automatically.
3. Once the pipeline completes, verify the application:
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
├── Jenkinsfile
├── docker-compose.yaml         ← Runs Jenkins + Docker-in-Docker locally
└── myapp/
    ├── Dockerfile              ← Multi-stage build (Maven → runtime image)
    ├── pom.xml
    └── src/main/java/com/example/myapp/
        ├── Application.java
        └── HelloController.java
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Jenkins can't connect to EC2 | Check Security Group port 22 is open for Jenkins IP |
| Docker build fails | Ensure Maven build (`mvn package`) succeeds first locally |
| `docker: command not found` on Jenkins | Mount Docker socket into the Jenkins container or use Docker-in-Docker |
| EC2 container not accessible | Verify port 8090 is open in Security Group inbound rules |
| GitHub webhook not firing | Use ngrok if Jenkins is running locally; check webhook delivery logs in GitHub |

---

## References
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EC2 Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)
- [Spring Boot Docs](https://docs.spring.io/spring-boot/docs/current/reference/html/)
