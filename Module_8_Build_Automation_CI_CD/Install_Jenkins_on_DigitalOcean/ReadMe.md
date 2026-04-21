
# Install Jenkins on DigitalOcean

## Overview
This guide walks through setting up Jenkins on a DigitalOcean Droplet for CI/CD automation.

## Prerequisites
- DigitalOcean account with an active Droplet
- Ubuntu 24.04.4 LTS (or compatible)
- SSH access to your Droplet
- Basic command-line knowledge

## Installation Steps

### 1. Update System Packages
```bash
sudo apt update
sudo apt upgrade -y
```

### 2. Install Java
Jenkins requires Java to run:
```bash
sudo apt install -y openjdk-11-jdk
java -version
```

### 3. Add Jenkins Repository
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
```

### 4. Install Jenkins
```bash
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 5. Access Jenkins
Get the initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open Jenkins in your browser: `http://<your-droplet-ip>:8080`

## Configuration
- Complete the setup wizard
- Install recommended plugins
- Create your first admin user

## Next Steps
- Configure build jobs
- Set up webhooks for CI/CD pipelines
- Integrate with version control systems
