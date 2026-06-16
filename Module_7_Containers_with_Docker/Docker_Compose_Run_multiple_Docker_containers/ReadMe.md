# Docker Compose: Run Multiple Docker Containers

## Overview
Docker Compose is a tool for defining and running multi-container Docker applications. It uses a YAML file to configure your application's services.

## Prerequisites
- Docker installed
- Docker Compose installed
- Basic understanding of Docker containers

## Getting Started

### 1. Create a `docker-compose.yml` file
We need to create the docker-compose file that we can create the strucutre of the 
containers that we need to create and maintain the containers running on the docker. 

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
### 2. Creat the network 
We need to create a network for the containers to run and maintain the containers in a secure network.
```bash
docker create network mongo-express-network 
```

### 3. Run containers
We need to command to execute the command to start running the containers.
```bash
docker-compose up -d
```

### 4. Stop containers
We need to execute command to stop the running the containers. 
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
