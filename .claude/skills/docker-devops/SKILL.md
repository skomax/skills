---
name: docker-devops
description: Docker, Docker Compose, CI/CD, deployment patterns. Multi-stage builds, dev/prod separation, container orchestration, health checks, and monitoring.
---

# Docker & DevOps Skill

## When to Activate
- Creating or modifying Dockerfiles and docker-compose configs
- Setting up CI/CD pipelines
- Deploying multi-service applications
- Troubleshooting container issues
- Configuring dev vs production environments

## Multi-Stage Dockerfile (Python)

```dockerfile
# Stage 1: Base with dependencies
FROM python:3.12-slim AS base
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Development (hot reload, debug tools)
FROM base AS dev
RUN pip install debugpy pytest
COPY . .
CMD ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--reload"]

# Stage 3: Production (minimal, secure)
FROM base AS production
RUN addgroup --gid 1001 --system app && \
    adduser --uid 1001 --system --ingroup app app
USER app
COPY --chown=app:app . .
HEALTHCHECK --interval=30s --timeout=3s CMD python -c "import httpx; httpx.get('http://localhost:8000/health')" || exit 1
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

## Multi-Stage Dockerfile (Node.js)

```dockerfile
FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS dev
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000 9229
CMD ["npm", "run", "dev"]

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build && npm prune --production

FROM node:22-alpine AS production
WORKDIR /app
RUN addgroup -g 1001 -S app && adduser -S app -u 1001
USER app
COPY --from=build --chown=app:app /app/dist ./dist
COPY --from=build --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/package.json ./
ENV NODE_ENV=production
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:3000/health || exit 1
CMD ["node", "dist/server.js"]
```

## Docker Compose: Dev + Prod Pattern

```yaml
# docker-compose.yml (base - shared config)
services:
  app:
    build: { context: . }
    env_file: .env
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

```yaml
# docker-compose.override.yml (dev - auto-loaded)
services:
  app:
    build: { target: dev }
    ports:
      - "8000:8000"
      - "5678:5678"  # Python debugger
    volumes:
      - .:/app
      - /app/__pycache__
    environment:
      - LOG_LEVEL=debug
  db:
    ports:
      - "127.0.0.1:5432:5432"
```

```yaml
# docker-compose.prod.yml (production - explicit)
services:
  app:
    build: { target: production }
    restart: always
    deploy:
      resources:
        limits: { cpus: "2.0", memory: 1G }
    ports:
      - "8000:8000"
```

## .dockerignore (always include)

```
.git
.github
.claude
.env
.env.*
!.env.example
__pycache__
*.pyc
node_modules
.next
dist
coverage
tests/
docs/
*.md
!README.md
docker-compose*.yml
Dockerfile*
.vscode
.idea
```

## CI/CD with GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: test_db
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports: ["5432:5432"]
        options: --health-cmd pg_isready --health-interval 5s --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: pytest --cov=app -v
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/build-push-action@v5
        with:
          context: .
          target: production
          push: false
          tags: app:${{ github.sha }}
```

## Essential Commands

```bash
# Development
docker compose up                    # Start dev (auto-loads override)
docker compose up --build            # Rebuild and start
docker compose logs -f app           # Follow app logs
docker compose exec app bash         # Shell into container

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Debugging
docker compose ps                    # Service status
docker stats                         # Resource usage
docker compose exec app python -m pytest  # Run tests in container

# Cleanup
docker compose down                  # Stop containers
docker compose down -v               # Stop + remove volumes (DATA LOSS)
docker system prune -a               # Remove all unused images
```

## Health Check Patterns

- HTTP endpoint check: `curl -f http://localhost:PORT/health`
- Database check: `pg_isready`, `redis-cli ping`
- Process check: `pgrep -f "process_name"`
- Always set: interval, timeout, retries, start_period
