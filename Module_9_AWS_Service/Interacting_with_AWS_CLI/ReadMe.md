
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
We need to execute commands to install the aws cli into the local desktop and to be able to access the AWS servers'.
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. Configure Credentials
To set up the access to the spceific Region and AWS account access, we need to configure the environment to be able to access the identity.
```bash
aws configure
```

### 3. Verify Installation
After configuring the Region and the Avaliability Zone, we need to access the identity to the AWS CLI on the remote desktop and create/destroy EC2...
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
