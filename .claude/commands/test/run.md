# Run Tests

Run project tests with coverage report.

## Instructions

If `$ARGUMENTS` is provided, use it as a test path or pattern to run specific tests.

1. Detect the project type:
   - `pyproject.toml` or `pytest.ini` -> Python/pytest
   - `package.json` with test script -> JavaScript/TypeScript
   - `Gemfile` with rspec -> Ruby/RSpec

2. Run appropriate test command:

### Python
```bash
# Full suite
pytest --cov=src --cov-report=term-missing -v --tb=short

# Specific tests (if $ARGUMENTS provided)
# pytest $ARGUMENTS -v --tb=short
```

### JavaScript/TypeScript
```bash
npm test -- --coverage
# or
npx vitest run --coverage
```

### Ruby
```bash
bundle exec rspec --format documentation
```

3. If running in Docker:
```bash
docker compose exec app pytest --cov=src -v
```

4. Report:
   - Total tests: passed / failed / skipped
   - Coverage percentage
   - Uncovered files/lines that need attention
   - Any flaky or slow tests (>5s)
