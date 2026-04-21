
# CD: Deploy Application with Jenkins Pipeline to EC2 Instance (Automatically with Docker)

## Overview
This module demonstrates how to set up a continuous deployment (CD) pipeline using Jenkins to automatically build and deploy applications to an AWS EC2 instance using Docker containers.

## Prerequisites
- AWS Account with EC2 access
- Jenkins server installed and configured
- Docker installed on EC2 instance
- Git repository with application code
- IAM credentials configured

## Key Components
- **Jenkins**: CI/CD orchestration server
- **Docker**: Containerization platform
- **EC2 Instance**: Target deployment environment
- **Git**: Source code management

## Steps

### 1. Configure EC2 Instance
- Launch an EC2 instance (Ubuntu recommended)
- Install Docker and Docker Compose
- Create IAM role for EC2 instance

### 2. Set Up Jenkins Pipeline
- Create new Jenkins job with pipeline configuration
- Define stages: Build, Test, Deploy
- Configure GitHub webhook for automatic triggers

### 3. Docker Configuration
- Create Dockerfile for application
- Build and push image to Docker registry
- Pull and run container on EC2

### 4. Deployment Automation
- Configure deployment scripts
- Set up EC2 security groups
- Test end-to-end pipeline

## References
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [AWS EC2 Guide](https://docs.aws.amazon.com/ec2/)
- [Docker Documentation](https://docs.docker.com/)
