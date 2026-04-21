
# Interacting with AWS CLI

## Overview
This module covers how to interact with Amazon Web Services (AWS) using the AWS Command Line Interface (CLI).

## Prerequisites
- AWS Account
- AWS CLI installed and configured
- IAM credentials (Access Key ID and Secret Access Key)

## Topics Covered
- Installing and configuring AWS CLI
- Basic AWS CLI commands
- Working with EC2, S3, and other AWS services
- IAM and authentication
- CloudFormation and Infrastructure as Code

## Getting Started

### 1. Install AWS CLI
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. Configure Credentials
```bash
aws configure
```

### 3. Verify Installation
```bash
aws --version
aws sts get-caller-identity
```

## Common Commands
- List S3 buckets: `aws s3 ls`
- List EC2 instances: `aws ec2 describe-instances`
- View IAM users: `aws iam list-users`

## Resources
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)

## Next Steps
Explore individual services and practice with real AWS resources.
