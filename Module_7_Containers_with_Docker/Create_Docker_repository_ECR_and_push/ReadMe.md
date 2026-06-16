
# Create Docker Repository (ECR) and Push

## Overview
This module covers creating an Amazon Elastic Container Registry (ECR) repository and pushing Docker images to it.

## Prerequisites
- AWS Account with appropriate permissions
- Docker installed and configured
- AWS CLI configured with credentials
- Optionally, we would use the Nexus Repository.

## Steps

### 1. Create an ECR Repository
To be able to upload the Docker Image to the AWS' Elastic Container Registry, we need to allocate the repository to the Docker Image. The allocation would require specific name for the repo and the region(Avaliability zone) for the repo to be created. 
```bash
aws ecr create-repository --repository-name my-app --region us-east-1
```

### 2. Authenticate Docker with ECR
We need to secure a connection to the ECR and the Docker.
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Build and Tag Docker Image
We create the image and and a tag to specify the image. 
```bash
docker build -t my-app:latest .
docker tag my-app:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

### 4. Push Image to ECR
We need to push the tagged image into the ECR.
```bash
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/my-app:latest
```

## Verification
We can check the ECR by listing the image to check if the upload was successful:
```bash
aws ecr describe-images --repository-name my-app --region us-east-1
```

## Resources
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Docker Push Guide](https://docs.docker.com/engine/reference/commandline/push/)
