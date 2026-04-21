
# Dockerize Node.js Application

## Overview
This module demonstrates how to containerize a Node.js application using Docker.

## Prerequisites
- Docker installed
- Node.js knowledge
- Basic CLI familiarity

## Getting Started

### Build the Docker Image
```bash
docker build -t nodejs-app .
```

### Run the Container
```bash
docker run -p 3000:3000 nodejs-app
```

## Project Structure
```
.
├── Dockerfile
├── package.json
├── package-lock.json
└── app.js
```

## Dockerfile Example
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

## Key Concepts
- **Image**: Blueprint for containers
- **Container**: Running instance of an image
- **Dockerfile**: Instructions to build an image

## Resources
- [Docker Documentation](https://docs.docker.com/)
- [Node.js Best Practices](https://nodejs.org/)
