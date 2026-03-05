# Docker Rebuild & Test

Rebuild Docker containers and verify everything works.

## Instructions

1. Check what changed:
   ```bash
   git diff --name-only main...HEAD
   ```
   If `$ARGUMENTS` contains a service name, rebuild only that service.

2. Determine rebuild scope:
   - Dockerfile changed -> full rebuild with `--no-cache`
   - docker-compose.yml changed -> rebuild all affected services
   - requirements.txt / package.json changed -> rebuild app service
   - Source code only -> rebuild with cache (fast)

3. Execute rebuild based on scope:
   ```bash
   # Full rebuild (Dockerfile changed)
   docker compose down && docker compose build --no-cache && docker compose up -d

   # Standard rebuild (deps or source changed)
   docker compose down && docker compose up --build -d

   # Single service (if $ARGUMENTS provided)
   # docker compose up --build -d $ARGUMENTS
   ```

4. Verify:
   ```bash
   # Check all services are running
   docker compose ps

   # Check logs for errors
   docker compose logs --tail=30

   # Run health checks
   docker compose exec app curl -f http://localhost:8000/health || echo "HEALTH CHECK FAILED"
   ```

5. Run smoke tests if available:
   ```bash
   docker compose exec app pytest tests/integration/ -v --tb=short
   ```

6. Report status of all services and any issues found
