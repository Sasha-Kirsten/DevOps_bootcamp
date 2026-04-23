# Docker Local Development Environment

This exercise demonstrates setting up a local development environment using Docker with a Spring Boot Java application.

## Project Structure

- **Dockerfile**: Container configuration for building the application image
- **build.gradle**: Gradle build configuration
- **src/main/java**: Application source code including Spring Boot controller and database configuration
- **src/main/resources/static**: Static HTML files
- **src/test/java**: Unit tests

## Objectives

- Build and run a Docker container locally
- Mount volumes for live code reloading
- Configure environment variables
- Test the containerized application

# Docker Local Development

## Overview
This module covers Docker setup and best practices for local development workflows.

## Getting Started

### Prerequisites
- Docker installed and running
- Basic command line knowledge
- Familiarity with containerization concepts

### Quick Start
```bash
docker build -t app-name .
docker run -p 8000:8000 app-name
```

## Key Topics
- Dockerfile creation and optimization
- Image building and tagging
- Container lifecycle management
- Volume mounting for local development
- Networking between containers
- Docker Compose for multi-container applications

## Common Commands
```bash
docker ps                    # List running containers
docker build -t name .       # Build an image
docker run -it image bash    # Run container interactively
docker logs container-id     # View container logs
docker-compose up            # Start services defined in docker-compose.yml
```

## Best Practices
- Use `.dockerignore` to exclude unnecessary files
- Keep images lean with multi-stage builds
- Use environment variables for configuration
- Mount volumes for live code reload during development

## Resources
- [Docker Documentation](https://docs.docker.com/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)


