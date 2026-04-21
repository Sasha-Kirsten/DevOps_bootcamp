
# CD: Deploy Application with Jenkins Pipeline on EC2 Instance (Automatically with Docker Compose)

## Overview
This module demonstrates how to set up a continuous deployment (CD) pipeline using Jenkins to automatically deploy applications to an EC2 instance with Docker Compose.

## Prerequisites
- AWS account with EC2 access
- Jenkins server configured
- Docker and Docker Compose installed on EC2 instance
- Git repository with application code
- IAM permissions for EC2 operations

## Architecture
```
Git Repository → Jenkins Pipeline → EC2 Instance → Docker Compose → Running Application
```

## Setup Steps

### 1. Configure EC2 Instance
- Launch an EC2 instance (Ubuntu 24.04 LTS recommended)
- Install Docker and Docker Compose
- Set up security groups for Jenkins access

### 2. Jenkins Pipeline Configuration
- Create a new pipeline job in Jenkins
- Configure webhook for automatic triggering
- Set up credentials for EC2 SSH access

### 3. Deployment Process
- Pipeline pulls latest code from repository
- Builds Docker image
- Pushes to EC2 instance
- Executes `docker-compose up` for deployment

## Key Files
- `Jenkinsfile` - Pipeline definition
- `docker-compose.yml` - Service configuration
- Application source code

## Testing
Verify deployment by accessing the application URL on the EC2 instance.

## Troubleshooting
Check Jenkins logs and EC2 system logs if deployment fails.
