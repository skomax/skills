---
name: python-development
description: Python development patterns, async programming, type hints, project structure, and tooling for Python 3.10+ projects.
---

# Python Development Skill

## When to Activate
- Writing or reviewing Python code
- Setting up new Python projects
- Working with async/await patterns
- Data processing with pandas/numpy
- Building CLI tools or scripts

## Project Setup

### Recommended Structure
```
project/
  src/
    package_name/
      __init__.py
      main.py
      api/
      models/
      services/
      utils/
  tests/
    conftest.py
    unit/
    integration/
  pyproject.toml
  .python-version
  .env.example
```

### pyproject.toml Essentials
```toml
[project]
requires-python = ">=3.10"

[tool.black]
line-length = 88

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM"]

[tool.mypy]
python_version = "3.10"
strict = true

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing -v"
```

## Core Patterns

### Type Hints (mandatory)
```python
def process_items(items: list[str], limit: int | None = None) -> dict[str, int]:
    result = {item: len(item) for item in items}
    if limit:
        return dict(list(result.items())[:limit])
    return result
```

### Async/Await for I/O
```python
import asyncio
import aiohttp

async def fetch_data(urls: list[str]) -> list[dict]:
    async with aiohttp.ClientSession() as session:
        tasks = [session.get(url) for url in urls]
        responses = await asyncio.gather(*tasks, return_exceptions=True)
        return [await r.json() for r in responses if not isinstance(r, Exception)]
```

### Dataclasses for Models
```python
from dataclasses import dataclass, field
from datetime import datetime

@dataclass
class Position:
    pool_address: str
    token0: str
    token1: str
    fee_tier: int
    lower_tick: int
    upper_tick: int
    liquidity: int
    created_at: datetime = field(default_factory=datetime.utcnow)
```

### Context Managers for Resources
```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def db_session():
    session = await create_session()
    try:
        yield session
        await session.commit()
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()
```

### Error Handling
```python
class AppError(Exception):
    """Base application error."""

class ValidationError(AppError):
    """Input validation failed."""

class ExternalServiceError(AppError):
    """External API call failed."""

# Always catch specific exceptions
try:
    result = await external_api.call()
except httpx.TimeoutException as e:
    raise ExternalServiceError(f"API timeout: {e}") from e
except httpx.HTTPStatusError as e:
    raise ExternalServiceError(f"API error {e.response.status_code}") from e
```

## Package Management

- Use `uv` (fastest) or `poetry` for dependency management
- Pin versions in lock files
- Separate dev dependencies from production
- Run `pip-audit` or `safety check` regularly

## Tooling Commands
```bash
# Format
black . && isort .
# Lint
ruff check . --fix
# Type check
mypy src/
# Test
pytest --cov=src -v
# Security
bandit -r src/ && pip-audit
```

## Key Libraries by Task

| Task | Library | Version |
|------|---------|---------|
| HTTP client | httpx / aiohttp | 0.27+ / 3.10+ |
| Data validation | pydantic | 2.x |
| Date/time | pendulum | 3.x |
| Config | pydantic-settings | 2.x |
| Logging | structlog | 24.x+ |
| Testing | pytest + pytest-asyncio | 8.x+ |
| Data processing | pandas + numpy | 2.x |
| Web scraping | beautifulsoup4 + httpx | 4.12+ |
