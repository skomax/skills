---
paths:
  - "**/package.json"
  - "**/package-lock.json"
  - "**/pyproject.toml"
  - "**/requirements*.txt"
  - "**/Pipfile"
  - "**/Gemfile"
  - "**/Gemfile.lock"
  - "**/Cargo.toml"
  - "**/go.mod"
  - "**/docker-compose*.yml"
  - "**/docker-compose*.yaml"
  - "**/Dockerfile*"
---
# Version Verification Rules

## Mandatory Verification Workflow

Before installing, recommending, or updating ANY framework or library:

1. **Resolve library ID** via context7 MCP: `resolve-library-id` with the library name
2. **Query documentation** via context7 MCP: `query-docs` with the resolved ID, asking for current stable version
3. **Compare** against the reference table below
4. **Use the latest stable version** unless there is a documented reason to pin an older one

If context7 MCP is unavailable, fall back to:
- `npm view <package> version` for Node.js packages
- `pip index versions <package>` for Python packages
- Web search for the package registry page

## Version Reference Table

| Framework | Min Version | Latest Verified | Last Checked |
|-----------|-------------|-----------------|--------------|
| Python | 3.12+ | 3.12 | 2026-03-05 |
| Node.js | 22.x LTS | 22.x | 2026-03-05 |
| Ruby | 3.3+ | 3.3 | 2026-03-05 |
| Next.js | 16.x | 16.1.6 | 2026-03-05 |
| React | 19.x | 19.x | 2026-03-05 |
| Tailwind CSS | 4.x | 4.1 | 2026-03-05 |
| FastAPI | 0.128+ | 0.128.0 | 2026-03-05 |
| aiogram | 3.x | 3.25.0 | 2026-03-05 |
| SQLAlchemy | 2.1+ | 2.1 | 2026-03-05 |
| web3.py | 7+ | 7.12.0 | 2026-03-05 |
| ethers.js | 6.x | 6.x | 2026-03-05 |
| viem | 2.x | 2.x | 2026-03-05 |
| Solidity | 0.8.x | 0.8.x | 2026-03-05 |
| discord.py | 2.x | 2.x | 2026-03-05 |
| discord.js | 14.x | 14.x | 2026-03-05 |
| Ruby on Rails | 8.x | 8.2.0 | 2026-03-05 |
| Pydantic | 2.x | 2.x | 2026-03-05 |
| pandas | 2.x | 2.x | 2026-03-05 |
| httpx | 0.27+ | 0.27 | 2026-03-05 |
| Celery | 5.x | 5.x | 2026-03-05 |

## Red Flags to Catch

- Any version **below the minimum** in the reference table
- Any **alpha/beta/rc** version used in production code
- Any library marked as **unmaintained or deprecated** (check last commit date, open issues)
- Docker base images using **`:latest`** tag instead of specific versions
- Lock files (`package-lock.json`, `poetry.lock`) not present or not committed

## Stale Check

If the "Last Checked" date for a framework is **older than 90 days**, re-verify the version via context7 MCP before using it. Update the table after verification.

## Docker Image Versions

Always pin specific versions in Dockerfiles:
```dockerfile
# GOOD
FROM python:3.12-slim
FROM node:22-alpine

# BAD
FROM python:latest
FROM node:latest
```
