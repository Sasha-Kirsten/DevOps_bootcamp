# Deploy Docker Application Server with Docker Compose

## Overview
This guide demonstrates how to deploy a containerized application server using Docker Compose for orchestration and simplified multi-container management.

## Prerequisites
- Docker and Docker Compose installed
- Basic understanding of Docker concepts
- Ubuntu 24.04.4 LTS or compatible environment

## Quick Start

### 1. Create a Docker Compose File
Using the already existing docker-compose.yml file, we can try use the docker-compose command to 
build up the yaml file so that we can try run both containers THe containers are MongoDB and the Mongo Express. 
```yaml
version: '3.8'

services:
    mongodb:
        image: mongodb:latest
        ports:
            - "27017:27017"
        environment:
          MONGO_INITDB_ROOT_USERNAME: admin
          MONGO_INITDB_ROOT_PASSWORD: password
    mongo_express:
        image: mongo_express:latest
        environment:
            ME_CONFIG_MONGODB_ADMINUSERNAME: admin
            ME_CONFIG_MONGODB_ADMINPASSWORD: password
        ports:
            - "8081:8081"
```

### 2. Deploy the Application
Here we are building up the docker-compose file.
```bash
docker-compose up -d docker-compose.yml
```

### 3. Verify Services
We need to observe the performance of the two containers.
```bash
docker-compose ps
docker-compose logs app
```

## Common Commands
- `docker-compose up` - Start services
- `docker-compose down` - Stop and remove services
- `docker-compose build` - Build images
- `docker-compose exec <service> <command>` - Run commands in a service

## Troubleshooting
Check logs: `docker-compose logs [service_name]`

## Resources
- [Docker Compose Documentation](https://docs.docker.com/compose/)