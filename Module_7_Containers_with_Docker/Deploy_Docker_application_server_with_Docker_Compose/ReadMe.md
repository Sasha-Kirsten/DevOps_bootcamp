# Deploy Docker Application Server with Docker Compose

## Overview
This guide demonstrates how to deploy a containerized application server using Docker Compose for orchestration and simplified multi-container management.

## Prerequisites
- Docker and Docker Compose installed
- Basic understanding of Docker concepts
- Ubuntu 24.04.4 LTS or compatible environment

## Quick Start

### 1. Create a Docker Compose File
```yaml
version: '3.8'
services:
    app:
        build: .
        ports:
            - "8080:8080"
        environment:
            - ENV=production
        depends_on:
            - db
    
    db:
        image: postgres:latest
        environment:
            - POSTGRES_PASSWORD=password
        volumes:
            - db_data:/var/lib/postgresql/data

volumes:
    db_data:
```

### 2. Deploy the Application
```bash
docker-compose up -d
```

### 3. Verify Services
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