# Production Deployment Checklist

Run through production deployment checklist before deploying.

## Instructions

### Pre-deployment Checks
1. [ ] All tests pass (`pytest` / `npm test`)
2. [ ] No linting errors (`ruff check .` / `eslint .`)
3. [ ] No security vulnerabilities (`pip-audit` / `npm audit`)
4. [ ] No hardcoded secrets in code (scan for API keys, tokens)
5. [ ] Environment variables documented in `.env.example`
6. [ ] Database migrations are ready (`alembic upgrade head` / `rails db:migrate`)
7. [ ] CHANGELOG.md updated with new version
8. [ ] Docker builds successfully: `docker compose -f docker-compose.yml -f docker-compose.prod.yml build`

### Deployment Steps
1. Create release branch or tag
2. Run full test suite in CI
3. Build production Docker images
4. Run database migrations
5. Deploy with zero-downtime strategy
6. Verify health endpoints
7. Monitor logs for 15 minutes post-deploy

### Post-deployment Verification
1. [ ] Health check endpoints responding (all services)
2. [ ] Key user flows working (login, main features)
3. [ ] No error spikes in logs
4. [ ] Performance metrics within normal range
5. [ ] Rollback plan documented if issues found

### Rollback Procedure
```bash
# Quick rollback to previous version
docker compose -f docker-compose.yml -f docker-compose.prod.yml down
git checkout <previous-tag>
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
alembic downgrade -1  # If migration needs reversal
```
