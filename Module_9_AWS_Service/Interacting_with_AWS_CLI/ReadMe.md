
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
To set up the access to the spceific Region and AWS account access, we need to configure the Access Key ID, Secrey Access Key, region the EC2 Instance would be deployed and output format.  
We need to check the security group the ec2 instance would be in, like the 'FromPort' and the 'Vpcs' id of the VPC.
```bash
aws configure
aws ec2 describe-security-groups
aws ec2 create-security-group --group-name my-sg --description "My SG" --vpc-id  vpc-id-number
aws ec2 describe-security-groups --groups-ids sg-id-number
aws ec2 authroize-security-group-ingress \
> --group-id sg-id-number \
> --protocol tcp \
> --port 22 \
> --cidr ip-address/range
aws ec2 create-key-pair \
> --key-name MyKpCli \
> --query 'KeyMaterial'\
> --output text > MyKpCli.pem 
aws ec2 run-instances \
> --image-id ami-number \
> --count 1 \
> --instance-type t2.micro \
> --key-name MyKpCli \
> --security-group-ids sg-number \
> --subnet-id subnet-number 
```



### 3. Testing different commands onto the AWS CLI 
To manage permissions and user access securely, we need to interact with the AWS Identity and Access Management (IAM) service. The following commands demonstrate how to create a new IAM user and group, add the user to the group, and assign necessary permission policies. We will also set up an AWS Console login profile with a password reset requirement, create a custom policy from a JSON file, and generate access keys for programmatic CLI access.
```bash
aws iam create-group --group-name MyGroupCli 

aws iam create-user --user-name MyUserCli

aws iam add-user-to-group --user-name MyUserCli --group-name MyGroupCli

aws iam get-group --group-name MyGroupCli

aws iam attach-user-policy

aws iam attach-group-policy --group-name MyGroupCli --policy-arn arn

aws iam list-attached-group-policies --group-name MyGroupCli 

aws iam create-login-profile --user-name MyUserCli --password MyPassword! --password-reset-required

aws iam create-policy --policy-name changedPwd --policy-document file://path-to-change-policy.json

aws iam attach-group-policy --group-name MyGroupCli --policy-run arn::aws::

aws iam create-access-key --user-name MyUserCli 

aws uan create-user --user-name test 
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
