# Project Initialization

Set up a new project with proper structure and configuration.

## Instructions

1. Ask the user for:
   - Project type (API, web app, bot, data processing)
   - Technology stack (Python/Node.js/both)
   - Database needed? (PostgreSQL, Redis, MongoDB)
   - Docker required? (yes/no)
   - Authentication needed? (yes/no)

2. Create the project structure based on answers:

### Python API (FastAPI)
```
src/app/
  main.py, config.py, dependencies.py
  api/v1/endpoints/
  models/
  schemas/
  services/
  db/
tests/conftest.py, unit/, integration/
alembic/
Dockerfile
docker-compose.yml
pyproject.toml
.env.example
.gitignore
CLAUDE.md
```

### Next.js Frontend
```
src/
  app/(layout, page, globals.css)
  components/ui/, layout/
  lib/
  hooks/
  types/
tailwind.config.ts
next.config.ts
Dockerfile
.env.example
```

### Telegram Bot
```
bot/
  main.py, config.py
  handlers/
  keyboards/
  middlewares/
  services/
  states/
Dockerfile
docker-compose.yml
pyproject.toml
.env.example
```

### Data Processing
```
src/
  pipelines/
  extractors/
  transformers/
  loaders/
  utils/
tests/
notebooks/
data/raw/, data/processed/
pyproject.toml
Dockerfile
.env.example
```

3. Generate all configuration files with sensible defaults
4. Create .env.example with all required variables
5. Initialize git repository
6. Create initial CLAUDE.md with project context
