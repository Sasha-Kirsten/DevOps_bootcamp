
# Deploy Web Application on EC2 Instance Manually

## Overview
This module covers the process of manually deploying a web application to an AWS EC2 instance.

## Prerequisites
- AWS account with appropriate permissions
- EC2 instance running (Ubuntu/Amazon Linux recommended)
- SSH access configured
- Basic knowledge of Linux command line

## Steps

### 1. Launch an EC2 Instance
- Navigate to AWS Console → EC2 Dashboard
- Click "Launch Instance"
- Select an appropriate AMI (Amazon Machine Image)
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
