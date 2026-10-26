# Demo Project: Create a Server and Deploy a Java Application on DigitalOcean

## Overview

This project demonstrates the basic process of deploying a Java application to a Linux server hosted on DigitalOcean.

The goal is to:

1. Create and configure a DigitalOcean Droplet.
2. Secure the Droplet by creating a dedicated non-root Linux user.
3. Install Java and Gradle.
4. Build a Java application with Gradle.
5. Copy the application to the Droplet and run it.

> **Current repository status:** This directory currently contains documentation only. Add the Java/Gradle application and any deployment automation before treating this as a fully reproducible deployment project.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| DigitalOcean | Cloud platform that hosts the Linux Droplet. |
| Linux | Operating system used by the server. |
| Java | Runtime required to run the application. |
| Gradle | Build tool used to compile and package the Java application. |

## Deployment Flow

```text
Developer workstation
	|
	| Build with Gradle
	v
Java application JAR file
	|
	| Secure copy / CI-CD deployment
	v
DigitalOcean Linux Droplet
├── Non-root deployment user
├── Java runtime
├── Application JAR
└── systemd service → Java application
```

## Prerequisites

Before starting, make sure you have:

- A DigitalOcean account.
- An SSH key added to your DigitalOcean account.
- A Linux Droplet, such as Ubuntu LTS.
- A Java project that uses Gradle and can build a runnable JAR file.
- Java and Gradle installed locally for building the application.

## Implementation Steps

### 1. Create the DigitalOcean Droplet

Create a Linux Droplet in the required region and add your SSH public key during creation.

For a learning project, use a small Droplet. For a real application, select a size based on the application's CPU, memory, storage, and traffic needs.

### 2. Update the Linux server

Connect to the Droplet with SSH and update the package list:

```bash
sudo apt update
sudo apt upgrade
```

### 3. Create a non-root deployment user

Avoid deploying and running applications as `root`. Create a dedicated user for administration or deployment:

```bash
sudo adduser deploy
sudo usermod -aG sudo deploy
```

Copy the SSH public key to the new user's `~/.ssh/authorized_keys` file, then verify that you can connect as that user before disabling root SSH access.

> **Security best practice:** Use SSH keys instead of passwords, restrict SSH access with a firewall, and use the non-root user for normal administration and deployment work.

### 4. Install Java

Install a supported Java runtime. For example, on Ubuntu:

```bash
sudo apt install openjdk-17-jre-headless
java -version
```

Use the Java version required by the Gradle application. Java 17 is an LTS release, but the application may require a different supported version.

### 5. Build the application with Gradle

From the Java application's source directory, build the project:

```bash
./gradlew clean build
```

Gradle typically creates the application JAR file in `build/libs/`. Confirm that the build succeeds and identify the generated JAR before deploying it.

### 6. Copy the application to the Droplet

Create an application directory on the server and make the deployment user its owner:

```bash
sudo mkdir -p /opt/my-java-app
sudo chown deploy:deploy /opt/my-java-app
```

Copy the built JAR file from the local computer to the server using a secure method such as `scp`, `rsync`, or a CI/CD pipeline.

### 7. Run the Java application

Connect as the deployment user and start the application:

```bash
java -jar /opt/my-java-app/my-java-app.jar
```

For a temporary learning test, this is enough. For a long-running application, use `systemd` so the application runs in the background and starts again after a server reboot.

## Verification

After deployment, verify that:

1. You can SSH to the server using the non-root deployment user.
2. Java is installed and reports the expected version.
3. Gradle creates the expected JAR file locally.
4. The JAR file exists in `/opt/my-java-app/` on the Droplet.
5. The application starts without errors.
6. The application responds on its configured port or health endpoint.

If the application is a web service, test it with a browser or `curl` from the server.

## Production Improvements

Before using this workflow in production, add:

- A DigitalOcean Cloud Firewall that restricts SSH and application traffic.
- A `systemd` service file to run the application as a non-root user and restart it after failures.
- Environment variables or a secret manager for database credentials, API keys, and other secrets.
- A reverse proxy such as Nginx or Caddy with HTTPS/TLS.
- Application logs, monitoring, health checks, backups, and alerting.
- A CI/CD pipeline that builds, tests, scans, and deploys a versioned JAR artifact.
- A rollback procedure that can return to the previous known-good application version.

## Resources

- [DigitalOcean Droplets documentation](https://docs.digitalocean.com/products/droplets/)
- [OpenJDK documentation](https://openjdk.org/)
- [Gradle Build Tool documentation](https://docs.gradle.org/)
- [systemd service documentation](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
