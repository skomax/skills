---
paths:
  - "**/*.py"
  - "**/*.js"
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.jsx"
  - "**/*.rb"
  - "**/*.sol"
  - "**/*.go"
  - "**/*.rs"
---
# Anti-Code-Duplication Rules

## Grep-Before-Create Mandate (CRITICAL)

Before creating ANY new function, class, utility, or module:

1. **Search by name** — Grep the codebase for functions/classes with similar names
   ```
   # Example: before creating format_price(), search for existing formatters
   Grep: "def format_price\|def format_amount\|def format_currency"
   Grep: "formatPrice\|formatAmount\|formatCurrency"
   ```

2. **Search by purpose** — Grep for keywords related to the functionality
   ```
   # Example: before creating an HTTP client wrapper
   Grep: "httpx.AsyncClient\|aiohttp.ClientSession\|requests.Session"
   ```

3. **Check exports** — Look at `__init__.py` (Python) or `index.ts` (TypeScript) files in relevant directories for already-exported utilities

4. **Extend, don't duplicate** — If a similar function exists, extend or refactor it rather than creating a new one. Add parameters to generalize existing code.

## Dependency Deduplication

Before adding ANY new dependency:
1. Check `pyproject.toml` / `package.json` / `Gemfile` — is it already installed?
2. Check if an existing dependency already provides the needed functionality (e.g., don't add `axios` if `httpx` is already in the project)
3. Prefer stdlib solutions over new dependencies when practical

## Architecture Documentation

Projects with more than 10 source files must maintain `docs/architecture.md` with these sections:

### Module Map
```markdown
| Directory | Purpose |
|-----------|---------|
| src/services/ | Business logic layer |
| src/utils/ | Shared utility functions |
| src/models/ | Data models / ORM entities |
| src/api/ | API endpoints / route handlers |
```

### Key Functions Registry
```markdown
| Function | Location | Purpose |
|----------|----------|---------|
| format_price() | src/utils/formatters.py:15 | Format price with decimals |
| validate_address() | src/utils/validators.py:8 | Check Ethereum address checksum |
| get_pool_data() | src/services/pool.py:42 | Fetch pool state from chain |
```

### Service Dependencies
```markdown
orchestrator -> [parser_worker, poster_worker, redis]
api -> [db, redis, auth_service]
worker -> [db, external_api, redis]
```

Update this file incrementally during each development session — not as a separate task.

## Centralized Export Patterns

### Python
```python
# src/utils/__init__.py — re-export public API
from .formatters import format_price, format_amount
from .validators import validate_address, validate_tx_hash
from .converters import tick_to_price, price_to_tick
```

### TypeScript
```typescript
// src/utils/index.ts — barrel file
export { formatPrice, formatAmount } from './formatters'
export { validateAddress } from './validators'
```

Never import from deep internal paths when a public re-export exists:
```python
# GOOD
from src.utils import format_price

# BAD
from src.utils.formatters import format_price  # if re-exported in __init__.py
```

## Common Duplication Anti-Patterns

Watch for and prevent these patterns:
- Multiple HTTP client wrappers in different modules
- Duplicate validation logic in controllers AND services
- Repeated database query patterns that should be repository methods
- Configuration loading duplicated across files
- Error handling logic copy-pasted instead of using a shared handler
- String formatting/parsing utilities recreated in multiple places
- Logger setup repeated in every file (use a shared logger factory)

## When Duplication Is Acceptable

- **Test files**: test fixtures can repeat setup code for clarity and test isolation
- **Generated code**: auto-generated files may have intentional duplication
- **Cross-service boundaries**: microservices may intentionally duplicate simple types to avoid coupling
- **Prototyping**: during initial development, duplication is OK — refactor after third occurrence
