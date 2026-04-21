
# Complete CI/CD Pipeline with Docker Compose and Dynamic Versioning

## Overview
This module demonstrates how to build a complete CI/CD pipeline using Docker Compose and implement dynamic versioning strategies for containerized applications.

## Prerequisites
- Docker and Docker Compose installed
- Basic understanding of CI/CD concepts
- AWS account with appropriate permissions
- Git for version control

## Key Concepts

### Docker Compose
- Multi-container application orchestration
- Service definition and networking
- Volume management and data persistence

### Dynamic Versioning
- Semantic versioning (Major.Minor.Patch)
- Automated version bumping
- Git tags and release management

## Project Structure
```
.
├── docker-compose.yml
├── Dockerfile
├── scripts/
│   ├── build.sh
│   ├── deploy.sh
│   └── version.sh
├── src/
└── tests/
```

## Getting Started

1. Clone the repository
2. Configure environment variables
3. Build and run with Docker Compose
4. Execute CI/CD pipeline scripts

## Pipeline Stages
- **Build**: Compile code and create Docker image
- **Test**: Run automated test suites
- **Version**: Apply dynamic versioning
- **Deploy**: Push to registry and deploy

## Resources
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Semantic Versioning](https://semver.org/)
- [AWS CI/CD Services](https://aws.amazon.com/devops/continuous-integration/)
