
# Deploy Web Application on EC2 Instance Manually

## Overview
This module covers the process of manually deploying a web application to an AWS EC2 instance.

## Prerequisites
- AWS account with appropriate permissions
- EC2 instance running (Ubuntu/Amazon Linux recommended)
- SSH access configured
- Basic knowledge of Linux command line

## Before Deploy web to EC2 (Elastic Cloud Compute) (Optional)
### 1. If you are using a created IAM Account (not root user account), you will need to create an asyncouruous key (public - private key). 
### 2. To do this, you will need to go to IAM of the root account that created IAM user and generate a "Access Key" under the section Security credentials. 
### 3. After creating the key, you will need to install the private key into you .ssh branch through your terminal.
### 4. Then proceed to the steps of deploy the web application to the EC2 Instance. 

## Steps
### 1. Launch an EC2 Instance
- Navigate to AWS Console → EC2 Dashboard
- Click "Launch Instance" (big orange button)
- Select a free tier AMI (Amazon Machine Image)
- Choose instance type (t2.micro recommended for testing)
- Configure security groups to allow HTTP (80), HTTPS (443), and SSH (22)

### 2. Connect to Your Instance
```bash
ssh -i your-key.pem ec2-user@your-instance-ip
```

### 3. Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

### 4. Install Required Dependencies
```bash
sudo apt install -y nodejs npm
```

### 5. Deploy Your Application
- Upload your application files using SCP or Git
- Install dependencies: `npm install`
- Start the application

### 6. Configure Web Server
- Set up Nginx or Apache as a reverse proxy
- Configure firewall rules

## Troubleshooting
- Verify security group rules allow traffic
- Check application logs for errors
- Ensure instance has sufficient resources

## Resources
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Linux Commands Reference](https://linux.die.net/)
