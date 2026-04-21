
# Create Docker Repository (ECR) and Push

## Overview
This module covers creating an Amazon Elastic Container Registry (ECR) repository and pushing Docker images to it.

## Prerequisites
- AWS Account with appropriate permissions
- Docker installed and configured
- AWS CLI configured with credentials

## Steps

### 1. Create an ECR Repository
```bash
aws ecr create-repository --repository-name my-app --region us-east-1
```

### 2. Authenticate Docker with ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Build and Tag Docker Image
```bash
docker build -t my-app:latest .
docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### 4. Push Image to ECR
```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## Verification
List images in your ECR repository:
```bash
aws ecr describe-images --repository-name my-app --region us-east-1
```

## Resources
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Push Guide](https://docs.docker.com/engine/reference/commandline/push/)
