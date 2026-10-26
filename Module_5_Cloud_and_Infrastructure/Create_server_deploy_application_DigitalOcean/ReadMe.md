# Demo Project: Create a Server and Deploy a Java Application on DigitalOcean

## Overview

This project documents my process for creating a Linux server on DigitalOcean and deploying a Java application built with Gradle.

I created a small DigitalOcean Droplet in the **Frankfurt, Germany** region, secured access to it, installed Java, and prepared it to receive a Java application artifact built with Gradle.

The project goal is to:

1. Set up and configure a DigitalOcean Droplet.
2. Create a dedicated non-root Linux user as a security best practice.
3. Build a Java application with Gradle.
4. Transfer the application JAR to the Droplet.
5. Run the application on the server.

> **Current repository status:** This folder currently contains my deployment documentation. Add the Java/Gradle application source, deployment scripts, and service configuration to make this project fully reproducible.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| DigitalOcean | Hosts the Linux Droplet. |
| Linux | Operating system used by the Droplet. |
| Java | Runtime required to execute the application. |
| Gradle | Builds and packages the Java application. |
| SSH / SCP | Securely accesses the server and transfers the built artifact. |

## Deployment Flow

```text
Developer workstation
	|
	| Build with Gradle
	v
Java application JAR file
	|
	| SCP or CI/CD deployment
	v
DigitalOcean Droplet in Frankfurt
├── Firewall restricts inbound access
├── Non-root deployment user
├── Java runtime
└── Java application JAR
```

## What I Did

### 1. Created a DigitalOcean Droplet

I created a small Linux Droplet in the Frankfurt, Germany region. A small Droplet is suitable for this learning project; a real application should be sized according to its CPU, memory, disk, and traffic requirements.

### 2. Restricted inbound network access

Before connecting to the Droplet, I created a firewall rule that allows inbound SSH access only from my current public IP address.

When the public IP address changes—for example, after changing networks—the firewall rule must be updated before I can connect again.

> **Security note:** Use a DigitalOcean Cloud Firewall to restrict port `22` to a trusted IP address, VPN, or CI/CD runner. Do not expose SSH to every IP address unless it is required and protected by additional controls.

### 3. Created an SSH key pair

On my local computer, I created an SSH key pair for secure access to the Droplet.

```bash
ssh-keygen -t ed25519 -C "digitalocean-deploy"
```

The **public key** is added to DigitalOcean or copied to the server. The **private key stays only on my local computer** and must never be uploaded to the Droplet, shared, or committed to Git.

After the Droplet is created, I can connect with:

```bash
ssh root@<droplet-ip-address>
```

For an existing server that permits password authentication, `ssh-copy-id` can add the public key:

```bash
ssh-copy-id root@<droplet-ip-address>
```

### 4. Updated the server packages

After connecting to the Droplet, I refreshed the package index and applied available updates:

```bash
sudo apt update
sudo apt upgrade
```

Updating the server installs available security and package updates before adding the Java runtime.

### 5. Created a non-root deployment user

Using `root` for everyday deployment is not recommended. The next security step is to create a dedicated deployment user:

```bash
sudo adduser deploy
sudo usermod -aG sudo deploy
```

Copy the public SSH key into `/home/deploy/.ssh/authorized_keys`, verify that the new user can connect, and then use that user for normal administration and application deployment.

```bash
ssh deploy@<droplet-ip-address>
```

### 6. Installed Java

The Java application needs a Java runtime on the Droplet. On Ubuntu, I can install Java with:

```bash
sudo apt install openjdk-17-jre-headless
java -version
```

The Java version should match the version required by the Gradle application. Java 17 is an LTS release, but a project may require another supported version.

### 7. Built the application with Gradle

On the local computer, I build the Java application with Gradle:

```bash
./gradlew clean build
```

The runnable JAR is typically created in the `build/libs/` directory.

### 8. Transferred the built application to the Droplet

Before transfer, I can compress a large deployment package if needed. For a standard Gradle JAR, the JAR is already compressed, so transferring it directly is usually enough.

First, create a directory for the application on the Droplet:

```bash
sudo mkdir -p /opt/my-java-app
sudo chown deploy:deploy /opt/my-java-app
```

Then copy the JAR from the local computer to the server as the deployment user:

```bash
scp build/libs/my-java-app.jar deploy@<droplet-ip-address>:/opt/my-java-app/
```

### 9. Ran the Java application

Connect to the Droplet as the deployment user and start the application:

```bash
java -jar /opt/my-java-app/my-java-app.jar
```

For this learning project, running the JAR directly confirms that the application can start. A long-running deployment should use `systemd` so it restarts after a server reboot or process failure.

## Verification

After deployment, verify that:

1. The Cloud Firewall allows SSH only from the intended source.
2. SSH access works with a key and the `deploy` user.
3. Java reports the required version with `java -version`.
4. Gradle produces the expected JAR in `build/libs/`.
5. The JAR exists under `/opt/my-java-app/` on the Droplet.
6. `java -jar` starts the application without errors.
7. The application responds on its expected port or health endpoint.

## Production Improvements

Before using this approach in production, add:

- Disable root SSH login and password-based SSH authentication after confirming non-root key access.
- Use a `systemd` service to run the application as the `deploy` user and restart it after failures.
- Use a reverse proxy such as Nginx or Caddy with HTTPS/TLS rather than exposing an application port directly.
- Store database credentials and API keys in environment variables or a secret manager, never in the JAR or Git.
- Add monitoring, logs, backups, health checks, alerting, and a rollback procedure.
- Build, test, scan, version, and deploy JAR artifacts through CI/CD instead of manually copying production files.

## Resources

- [DigitalOcean Droplets documentation](https://docs.digitalocean.com/products/droplets/)
- [DigitalOcean Cloud Firewalls documentation](https://docs.digitalocean.com/products/networking/firewalls/)
- [OpenJDK documentation](https://openjdk.org/)
- [Gradle Build Tool documentation](https://docs.gradle.org/)



