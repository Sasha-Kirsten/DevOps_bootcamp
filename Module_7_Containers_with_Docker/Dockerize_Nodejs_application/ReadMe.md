
# Dockerize Node.js Application

## Overview
This module demonstrates how to containerize a Node.js application using Docker.

## Prerequisites
- Docker installed
- Node.js knowledge
- Basic CLI familiarity

## Getting Started

### Build the Docker Image
We need to build the Docker Image to contain all the requirements receipes of the 
applications for the container run from. 
```bash
docker build -t nodejs-app .
```

### Run the Container
After building the Docker Image, we need to run the Image on the container that is 
connected to the port of 3000.
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
