# Project Health Check

Assess overall project health and status.

## Instructions

Run these checks and compile a status report:

### 1. Code Quality
```bash
# Python
ruff check . --statistics 2>/dev/null || echo "ruff not configured"
mypy src/ --ignore-missing-imports 2>/dev/null || echo "mypy not configured"

# JavaScript/TypeScript
npx eslint . --format compact 2>/dev/null || echo "eslint not configured"
npx tsc --noEmit 2>/dev/null || echo "typescript not configured"
```

### 2. Test Coverage
```bash
pytest --cov=src --cov-report=term-missing -q 2>/dev/null || npm test -- --coverage 2>/dev/null
```

### 3. Security
```bash
pip-audit 2>/dev/null || npm audit 2>/dev/null
```

### 4. Dependencies
- Check for outdated packages
- Check for known vulnerabilities
- Verify lock files are up to date

### 5. Docker Health
```bash
docker compose ps 2>/dev/null
docker compose logs --tail=10 2>/dev/null
```

### 6. Git Status
```bash
git status
git log --oneline -10
```

### Report Format
```
## Project Health Report

### Code Quality: [GOOD/WARN/FAIL]
- Linting errors: N
- Type errors: N

### Test Coverage: [XX%]
- Tests: N passed, N failed, N skipped

### Security: [GOOD/WARN/FAIL]
- Vulnerabilities: N critical, N high

### Docker: [UP/DOWN/PARTIAL]
- Services: N/N running

### Git: [CLEAN/DIRTY]
- Uncommitted changes: N files
- Branch: <current-branch>
```
