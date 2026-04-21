
# Docker Volumes: Persisting Data

## Overview
This module covers Docker volumes and persistent data storage in containerized applications.

## What are Docker Volumes?
Docker volumes are the mechanism for persisting data generated and used by Docker containers. Volumes are independent of the container lifecycle and allow data to survive container deletion.

## Key Concepts

### Volume Types
- **Named Volumes**: User-created volumes with explicit names
- **Anonymous Volumes**: Automatically created volumes without names
- **Bind Mounts**: Mount host directories directly into containers

### Benefits
- Data persistence across container restarts
- Easy data sharing between containers
- Simplified backup and migration
- Performance improvements on certain systems

## Common Docker Volume Commands

```bash
# Create a named volume
docker volume create my_volume

# List all volumes
docker volume ls

# Inspect a volume
docker volume inspect my_volume

# Remove a volume
docker volume rm my_volume

# Mount a volume to a container
docker run -v my_volume:/data my_image

# Mount a bind directory
docker run -v /host/path:/container/path my_image
```

## Best Practices
- Use named volumes for production applications
- Regularly back up important volumes
- Document volume requirements in Dockerfiles
- Use bind mounts only during development
- Clean up unused volumes regularly

## Next Steps
Explore volume drivers, multi-container volume sharing, and backup strategies.
