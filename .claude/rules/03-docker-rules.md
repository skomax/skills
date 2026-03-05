---
paths:
  - "**/Dockerfile*"
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/.dockerignore"
  - "**/docker/**"
---
# Docker Development Rules

## Mandatory Rebuild Triggers

ALWAYS rebuild Docker containers after changes to:
- Dockerfile or any build stage
- docker-compose.yml / docker-compose.override.yml
- Package files (requirements.txt, package.json, pyproject.toml, Gemfile)
- Environment variable definitions in compose files
- Volume mount configurations
- Network configurations
- Any init scripts mounted into containers

Rebuild command: `docker compose up --build`
Force full rebuild: `docker compose build --no-cache <service>`

## Dev vs Production Separation

### Development (docker-compose.yml + docker-compose.override.yml)
- Bind mounts for hot reload (source code mounted from host)
- Debug ports exposed (9229 for Node, 5678 for Python debugpy)
- Verbose logging (LOG_LEVEL=debug)
- Development database with seed data
- No resource limits

### Production (docker-compose.yml + docker-compose.prod.yml)
- Multi-stage build with minimal production image
- No source mounts, only built artifacts
- Resource limits (CPU, memory)
- Health checks on all services
- Restart policies (restart: always)
- Non-root user inside containers
- Read-only root filesystem where possible

Run production: `docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d`

## Dockerfile Best Practices

- Use specific base image tags (never `:latest`)
- Multi-stage builds: deps -> dev -> build -> production
- Run as non-root user in production stage
- HEALTHCHECK instruction for all services
- Minimize layers: group RUN commands with `&&`
- Copy dependency files first, then source (layer caching)
- Use `.dockerignore` to exclude: .git, node_modules, __pycache__, .env, tests/, docs/

## Docker Compose Patterns

### Workers and Orchestrator Architecture
```yaml
services:
  orchestrator:
    build: .
    command: python -m app.orchestrator
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
    restart: always

  worker-parsing:
    build: .
    command: python -m app.workers.parser
    deploy:
      replicas: 2
    depends_on:
      - orchestrator

  worker-posting:
    build: .
    command: python -m app.workers.poster
    depends_on:
      - orchestrator
```

### Networking
- Use custom networks to isolate frontend from backend services
- Database should only be reachable from backend network
- Expose ports on 127.0.0.1 in development (not 0.0.0.0)

### Volumes
- Named volumes for persistent data (databases)
- Bind mounts for development source code
- Anonymous volumes to protect container-specific directories (node_modules)

## Testing with Docker

After any Docker configuration change:
1. `docker compose down` - stop existing containers
2. `docker compose up --build` - rebuild and start
3. Verify all services are healthy: `docker compose ps`
4. Run smoke tests against containerized services
5. Check logs for errors: `docker compose logs --tail=50`
