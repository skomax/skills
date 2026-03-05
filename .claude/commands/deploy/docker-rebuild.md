# Docker Rebuild & Test

Rebuild Docker containers and verify everything works.

## Instructions

1. Check what changed:
   ```bash
   git diff --name-only HEAD~1
   ```

2. Determine rebuild scope:
   - Dockerfile changed -> full rebuild with `--no-cache`
   - docker-compose.yml changed -> rebuild all affected services
   - requirements.txt / package.json changed -> rebuild app service
   - Source code only -> rebuild with cache (fast)

3. Execute rebuild:
   ```bash
   docker compose down
   docker compose up --build -d
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
