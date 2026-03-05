---
paths:
  - "**/*.py"
  - "**/*.js"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.sol"
  - "**/*.rb"
---
# Core Development Rules

## Development Workflow (mandatory order)

1. **Research & Reuse** - search for existing implementations before writing new code. Check package registries (npm, PyPI, crates.io). Prefer battle-tested libraries over hand-rolled solutions.
2. **Plan First** - create implementation plan before coding. Identify dependencies, risks, break into phases. For large features generate: PRD, architecture doc, task list.
3. **TDD Approach** - write tests first (RED), implement to pass (GREEN), refactor (IMPROVE). Target 80%+ coverage.
4. **Code Review** - review code after writing. Address CRITICAL and HIGH issues before commit.
5. **Commit & Push** - follow conventional commits format, detailed messages.

## Coding Standards

- Use consistent naming: snake_case for Python, camelCase for JS/TS, PascalCase for components/classes
- Keep functions under 50 lines, files under 500 lines
- Single responsibility: one function = one task, one file = one module/component
- DRY: extract repeated code into reusable functions after third occurrence (see `08-anti-duplication.md` for grep-before-create workflow)
- Explicit over implicit: clear variable names, no magic numbers, typed parameters
- Error handling: catch specific exceptions, never bare except/catch
- No hardcoded values: use environment variables or config files for all settings
- Import order: stdlib, third-party, local (use isort for Python, eslint for JS/TS)

## Project Structure Standards

```
project-root/
  src/              # Source code
  tests/            # Tests (mirror src/ structure)
  docs/             # Documentation
  scripts/          # Utility scripts
  docker/           # Docker configs (if not in root)
  .env.example      # Environment template (never commit .env)
  .claude/          # Claude Code config
  CLAUDE.md         # Project-specific Claude instructions
  CHANGELOG.md      # Version history
```

## Framework Version Policy

- Always use the latest stable release of any framework
- Before adding a dependency, check: last update date, open issues count, maintenance status
- Pin exact versions in lock files (package-lock.json, poetry.lock, Pipfile.lock)
- Run dependency audit regularly: `npm audit`, `pip-audit`, `safety check`
- Never use alpha/beta versions in production without explicit approval

## When to Choose What

### Python vs Node.js
- **Python**: data processing, ML/AI, blockchain interaction, scripting, Telegram bots, backend APIs with heavy computation
- **Node.js**: real-time apps (WebSocket), frontend-adjacent backends, Discord bots (discord.js), high-concurrency I/O

### Framework Selection
- **FastAPI**: REST APIs, microservices, async operations, automatic OpenAPI docs
- **Django**: full-stack web apps with admin panel, ORM-heavy projects, rapid prototyping
- **Next.js**: SSR/SSG websites, dashboards, SaaS frontends
- **Express**: simple APIs, middleware-heavy architectures, WebSocket servers

### Database Selection
- **PostgreSQL**: primary database for structured data, ACID compliance, complex queries
- **Redis**: caching, session storage, queues, pub/sub, rate limiting
- **MongoDB**: document-oriented data, flexible schemas, rapid prototyping
- **SQLite**: local development, embedded apps, lightweight storage
