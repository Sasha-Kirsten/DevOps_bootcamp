# Install Jenkins on DigitalOcean

## Overview
This guide walks through setting up Jenkins on a DigitalOcean Droplet for CI/CD automation. Jenkins will run in a Docker container so that its installation and persistent data are isolated from the Droplet operating system.

> **Note:** This document is intentionally structured as a runbook. Add environment-specific details, screenshots, pipeline examples, and team conventions as the project grows.

## Prerequisites
- DigitalOcean account with an active Droplet
- Ubuntu 24.04.4 LTS (or compatible)
- SSH access to your Droplet
- Basic command-line knowledge
- A domain name (optional, but recommended for production use)
- A local SSH key added to the Droplet

## Before You Begin

### Create and connect to the Droplet

Create an Ubuntu Droplet from the DigitalOcean control panel. Choose a size that is appropriate for the expected number of Jenkins jobs; a small Droplet is suitable for learning and lightweight workloads.

Connect to the server from your local machine:

```bash
ssh root@<your-droplet-ip>
```

For safer day-to-day administration, create a non-root user, grant it `sudo` access, and use that account for subsequent work.

```bash
adduser <username>
usermod -aG sudo <username>
```

### Configure the DigitalOcean firewall

Create a cloud firewall and allow only the ports required by the server:

- `22/TCP` for SSH administration. Restrict this to your own public IP address where possible.
- `8080/TCP` temporarily for the Jenkins setup interface.
- `80/TCP` and `443/TCP` when Jenkins is later exposed through a reverse proxy with TLS.

Do not expose Jenkins agent port `50000` publicly unless inbound agents specifically require it. Prefer WebSocket agents or a private network when possible.

## Installation Steps

### 1. Update System Packages
Update the package index before installing software. Keeping the server updated reduces the chance of installing packages with known security issues.

```bash
sudo apt update
sudo apt upgrade -y
```

Optionally reboot when the upgrade installs a new kernel:

```bash
sudo reboot
```

### 2. Install Java
Jenkins runs inside Docker in the steps below, so Java is already included in the Jenkins image. Installing Java on the Droplet is optional unless you also plan to run Jenkins agents or other Java-based tools directly on the host.

```bash
sudo apt install -y openjdk-11-jdk
java -version
```


<!-- ### 3. Add Jenkins Repository
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
``` -->

### 3. Docker runs the Jenkins
Install Docker, enable it at startup, and verify that it is available. The `jenkins_home` named volume keeps Jenkins configuration, plugins, credentials, and build history when the container is recreated.

```bash
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo docker version
```

Run the Jenkins long-term support image:

```bash
sudo docker volume create jenkins_home
sudo docker run \
	--name jenkins \
	--restart unless-stopped \
	--detach \
	--publish 8080:8080 \
	--volume jenkins_home:/var/jenkins_home \
	jenkins/jenkins:lts
```

Check that the container is running and inspect its startup log if needed:

```bash
sudo apt install docker.io
docker run -p 8080:8080 -p 50000:50000 -d -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
```

> **Optional:** Add port `50000` only if you use traditional inbound Jenkins agents. Add `--publish 50000:50000` to the `docker run` command for that setup.

<!-- ### 4. Install Jenkins
```bash
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
``` -->

### 4. Access Jenkins
Get the initial administrator password from the **Docker container**:

```bash
sudo docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Open Jenkins in your browser at `http://<your-droplet-ip>:8080`. Paste the password into the setup wizard.

If the page does not load, check the DigitalOcean firewall, the Droplet's network rules, and the container status with `sudo docker ps`.

## Configuration

### 5. Complete the setup wizard

1. Choose **Install suggested plugins** for a first-time setup.
2. Create the first Jenkins administrator account. Do not continue to use the initial unlock password as a long-term credential.
3. Confirm the Jenkins URL. Use the Droplet IP address initially, then change it to your domain after configuring HTTPS.
4. Review the installed plugins and remove plugins that are not required.

### 6. Configure security and access

Before adding pipelines or connecting repositories, review these baseline settings:

- Keep Jenkins and all installed plugins up to date.
- Enable authentication and use individual accounts rather than sharing an administrator account.
- Use role-based permissions; grant administrator access only where necessary.
- Store repository tokens, cloud credentials, and passwords in **Manage Jenkins → Credentials**. Never commit them to a repository or place them directly in a `Jenkinsfile`.
- Back up the `jenkins_home` volume before major upgrades.
- Use a reverse proxy such as Nginx or Caddy with a TLS certificate before exposing Jenkins beyond a trusted network.

### 7. Configure source-control integration

Install the Git plugin if it was not installed by the suggested plugin set. Create a credential for your GitHub, GitLab, or other source-control provider, then test repository access from a pipeline job.

For webhook-driven builds, configure the repository webhook to use the public Jenkins URL. The exact webhook endpoint depends on the source-control provider and Jenkins plugin in use.

## Operating Jenkins

### Useful Docker commands

```bash
# Show the current Jenkins container state
sudo docker ps --filter name=jenkins

# Stream Jenkins logs
sudo docker logs --follow jenkins

# Restart Jenkins after configuration changes or troubleshooting
sudo docker restart jenkins

# Stop and start Jenkins
sudo docker stop jenkins
sudo docker start jenkins
```

### Upgrade Jenkins safely

Back up Jenkins data before changing the image version. Then pull the current LTS image, recreate the container with the same `jenkins_home` volume, and verify the web interface and a sample pipeline.

```bash
sudo docker pull jenkins/jenkins:lts
sudo docker stop jenkins
sudo docker rm jenkins
```

Re-run the Docker command from step 3. Because it uses the existing `jenkins_home` volume, Jenkins configuration and job data will be retained.

### Back up Jenkins data

The Jenkins home directory contains valuable configuration and credentials. Store encrypted backups outside the Droplet, such as in a protected object-storage bucket.

```bash
sudo docker run --rm \
	--volume jenkins_home:/data:ro \
	--volume "$PWD":/backup \
	alpine tar czf /backup/jenkins_home-backup.tar.gz -C /data .
```

Test restoration periodically. A backup is only a hypothesis until it has been restored successfully.

## Troubleshooting

| Problem | Suggested check |
| --- | --- |
| Jenkins page is unavailable | Confirm the container is running with `sudo docker ps` and that port `8080` is allowed by the firewall. |
| Initial password is missing | Review `sudo docker logs jenkins` and confirm the container name is `jenkins`. |
| Jenkins restarts repeatedly | Inspect container logs and ensure the Droplet has enough memory and disk space. |
| Repository checkout fails | Confirm Git is installed in the Jenkins image or agent, and verify the configured credential has repository access. |
| Disk fills up | Remove unused Docker images and review workspace/build retention settings in Jenkins. |

## Notes to Expand Later

Add the following topics as you continue developing this guide:

- Screenshots of Droplet creation, firewall configuration, and the Jenkins setup wizard
- A reverse-proxy and HTTPS configuration using a domain name
- A sample `Jenkinsfile` for building and testing an application
- GitHub or GitLab webhook configuration
- Jenkins agent setup and Docker-based build agents
- Backup retention, restore instructions, and disaster-recovery ownership

## Next Steps
- Configure a first pipeline job and commit its `Jenkinsfile` to source control
- Set up webhooks for CI/CD pipelines
- Integrate with version control systems
- Add a reverse proxy and HTTPS before using Jenkins for production workloads
- Define backup, upgrade, and plugin-review schedules
