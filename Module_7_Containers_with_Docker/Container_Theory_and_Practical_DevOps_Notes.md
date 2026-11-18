# Container Theory and Practical DevOps Notes

## Why containers matter in DevOps
Containers package application code, runtime, libraries, and dependencies into portable units. In DevOps, this reduces "works on my machine" issues and improves build, test, and deployment consistency.

---

## 1) Core container theory

### What is a container?
A container is a process isolated by Linux kernel features:
- **Namespaces**: isolate process trees, network, mounts, users.
- **cgroups**: enforce CPU/memory/I/O limits.
- **Union filesystems**: layer-based image storage.

### Container vs virtual machine
- **VM**: virtualizes hardware; includes full guest OS.
- **Container**: shares host kernel; lighter and faster start-up.

### OCI model (important)
Containers and images are standardized by OCI (Open Container Initiative):
- image format
- runtime behavior

This enables portability across Docker, containerd-based systems, and Kubernetes.

---

## 2) Images, layers, registries

### Image basics
An image is an immutable template made of layers.

Typical layer flow:
1. Base image (`ubuntu`, `node`, `python`)
2. Dependencies install
3. App source copy
4. Runtime command

### Tagging best practice
Avoid only `latest`; use versioned + traceable tags:
- `1.3.2`
- `1.3.2-<gitsha>`
- `main-<buildnum>`

### Digest pinning
Use digests in production deployments:
`myrepo/myapp@sha256:<digest>`

This guarantees exact binary identity.

---

## 3) Dockerfile essentials

### Minimal Node.js example
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 3000
CMD ["node", "app.js"]
```

### Java multi-stage example
```dockerfile
# Build stage
FROM gradle:8.10-jdk17 AS builder
WORKDIR /src
COPY . .
RUN gradle clean bootJar --no-daemon

# Runtime stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /src/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
```

### .dockerignore example
```text
.git
.gitignore
node_modules
build
dist
*.log
.env
```

Why: smaller build context, faster builds, reduced secret leakage risk.

---

## 4) Build, run, inspect workflow

### Build
```bash
docker build -t myapp:1.0.0 .
```

### Run
```bash
docker run -d --name myapp -p 8080:8080 myapp:1.0.0
```

### Observe
```bash
docker ps
docker logs -f myapp
docker inspect myapp
```

### Exec for debugging
```bash
docker exec -it myapp sh
```

---

## 5) Networking concepts

### Default bridge network
Containers can communicate by IP on the same Docker network.

### User-defined bridge (recommended)
Better DNS/service-name resolution:
```bash
docker network create app-net
docker run -d --name mongodb --network app-net mongo:7
docker run -d --name api --network app-net -e DB_HOST=mongodb myapp:1.0.0
```

### Port publishing
`-p hostPort:containerPort` maps host traffic into container.

Example:
```bash
docker run -p 3000:3000 myapp:1.0.0
```

---

## 6) Volumes and persistence

### Types
- **Named volumes** (recommended for persistent app data)
- **Bind mounts** (great for local dev)
- **tmpfs** (ephemeral memory-backed)

### Example named volume
```bash
docker volume create postgres_data
docker run -d --name pg \
  -e POSTGRES_PASSWORD=secret \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16
```

### Backup example
```bash
docker run --rm \
  -v postgres_data:/source \
  -v $PWD:/backup \
  alpine tar czf /backup/postgres_data_backup.tgz -C /source .
```

---

## 7) Docker Compose practical patterns

### Multi-container stack example
```yaml
services:
  mongodb:
    image: mongo:7
    container_name: mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: change_me
    volumes:
      - mongo_data:/data/db
    networks:
      - backend

  mongo-express:
    image: mongo-express:1.0.2
    container_name: mongo-express
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: change_me
      ME_CONFIG_MONGODB_URL: mongodb://admin:change_me@mongodb:27017/
    ports:
      - "8081:8081"
    depends_on:
      - mongodb
    networks:
      - backend

volumes:
  mongo_data:

networks:
  backend:
```

### Useful Compose commands
```bash
docker compose up -d
docker compose ps
docker compose logs -f
docker compose down
```

Tip: use `docker compose` (space) over legacy `docker-compose` when available.

---

## 8) Security best practices

1. Use minimal base images (`alpine`, distroless when appropriate).
2. Don’t run as root in containers.
3. Scan images for vulnerabilities.
4. Store secrets outside image (env/secret manager).
5. Pin dependency and base image versions.
6. Sign images and verify provenance where possible.

### Run as non-root example
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN addgroup -S app && adduser -S app -G app && chown -R app:app /app
USER app
CMD ["node", "app.js"]
```

---

## 9) Resource limits and reliability

Containers without limits can starve host resources.

### Runtime limits example
```bash
docker run -d --name api \
  --memory="512m" \
  --cpus="1.0" \
  myapp:1.0.0
```

### Healthcheck example
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1
```

---

## 10) Logging and observability

### Logs
- `docker logs -f <container>` for live troubleshooting
- Prefer structured JSON logs from applications

### Metrics and monitoring path
Container metrics can be collected by:
- cAdvisor
- node-exporter
- Prometheus
- visualized in Grafana

DevOps workflow:
`Container runtime metrics + app metrics + alerting rules`.

---

## 11) CI/CD container pipeline blueprint

1. Build image
2. Run unit/integration tests
3. Scan image (high/critical fail gate)
4. Tag image with version + commit SHA
5. Push to registry (ECR/GHCR/Artifactory)
6. Deploy by digest
7. Smoke test + rollback strategy

Example pseudo-commands:
```bash
docker build -t myapp:$VERSION .
docker tag myapp:$VERSION $REGISTRY/myapp:$VERSION
docker push $REGISTRY/myapp:$VERSION
DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $REGISTRY/myapp:$VERSION)
echo "Deploy using: $DIGEST"
```

---

## 12) Multi-architecture builds (important on Apple Silicon)

If build host is ARM64 but target environment is AMD64, use Buildx:
```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t $REGISTRY/myapp:1.0.0 \
  --push .
```

Inspect supported platforms:
```bash
docker buildx imagetools inspect $REGISTRY/myapp:1.0.0
```

---

## 13) Common failure cases and fixes

### `port is already allocated`
- Another process/container uses same port.
- Fix: free port or map another host port.

### `manifest unknown`
- Wrong tag/repository path.
- Fix: verify registry/tag spelling.

### `exec format error`
- Architecture mismatch (`amd64` image on `arm64` host).
- Fix: build multi-arch image.

### Container exits immediately
- Crash on startup or wrong command.
- Fix: inspect logs and image `CMD`/`ENTRYPOINT`.

### Data loss after restart
- Missing volume mount.
- Fix: attach named volume to data directory.

---

## 14) Practical checklist for DevOps projects

- [ ] Dockerfile uses pinned base image tag.
- [ ] `.dockerignore` exists.
- [ ] Container runs as non-root.
- [ ] Healthcheck configured.
- [ ] Resource constraints defined.
- [ ] Secrets are not hardcoded.
- [ ] Image scanned in CI.
- [ ] Artifact pushed to registry with version + SHA tag.
- [ ] Deployment uses digest.
- [ ] Rollback instructions tested.

---

## 15) Example end-to-end local test script

```bash
#!/usr/bin/env bash
set -euo pipefail

IMAGE="myapp:local"
PORT="8080"

docker build -t "$IMAGE" .
docker run -d --rm --name myapp-test -p "$PORT:8080" "$IMAGE"

for i in {1..20}; do
  if curl -fsS "http://localhost:$PORT/health" >/dev/null; then
    echo "Health check passed"
    break
  fi
  sleep 2
done

docker logs myapp-test | tail -n 50
docker stop myapp-test
```

---

## 16) Suggested next additions in this repository

For `Module_7_Containers_with_Docker`, add:
- `scripts/build-test-run.sh`
- `scripts/compose-smoke-test.sh`
- `scripts/scan-image.sh`
- `docker-compose.prod.yml` (with env-based configs)
- `SECURITY.md` for container hardening guidelines

This makes your portfolio examples operational and production-minded.
