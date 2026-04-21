
# Create Repository in AWS and Push to Private Docker Registry

## Overview
This module guides you through creating an AWS repository and pushing Docker images to a private Docker registry on AWS.

## Prerequisites
- AWS account with appropriate permissions
- Docker installed and configured
- AWS CLI configured with credentials
- Git installed

## Steps

### 1. Create AWS ECR Repository
```bash
aws ecr create-repository --repository-name my-app --region us-east-1
```

### 2. Authenticate Docker with AWS ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Build Docker Image
```bash
docker build -t my-app:latest .
```

### 4. Tag Image for ECR
```bash
docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### 5. Push to ECR
```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## Useful Commands
- List repositories: `aws ecr describe-repositories`
- View images: `aws ecr describe-images --repository-name my-app`
- Delete repository: `aws ecr delete-repository --repository-name my-app`

## References
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Documentation](https://docs.docker.com/)
