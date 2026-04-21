
# Docker Compose: Run Multiple Docker Containers

## Overview
Docker Compose is a tool for defining and running multi-container Docker applications. It uses a YAML file to configure your application's services.

## Prerequisites
- Docker installed
- Docker Compose installed
- Basic understanding of Docker containers

## Getting Started

### 1. Create a `docker-compose.yml` file
```yaml
version: '3.8'

services:
    web:
        image: nginx:latest
        ports:
            - "80:80"
        depends_on:
            - db

    db:
        image: postgres:latest
        environment:
            POSTGRES_PASSWORD: example
        volumes:
            - db_data:/var/lib/postgresql/data

volumes:
    db_data:
```

### 2. Run containers
```bash
docker-compose up -d
```

### 3. Stop containers
```bash
docker-compose down
```

## Common Commands
- `docker-compose up` - Start services
- `docker-compose down` - Stop and remove services
- `docker-compose logs` - View service logs
- `docker-compose ps` - List running services
- `docker-compose exec <service> <command>` - Execute command in service

## Best Practices
- Use meaningful service names
- Pin image versions
- Define resource limits
- Use environment files for configuration
- Mount volumes for persistent data
