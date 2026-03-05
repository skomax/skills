---
paths:
  - "**/test*/**"
  - "**/*test*.*"
  - "**/*spec*.*"
  - "**/conftest.py"
  - "**/jest.config.*"
  - "**/pytest.ini"
  - "**/pyproject.toml"
---
# Testing Rules

## Minimum Coverage: 80%

All projects must maintain 80%+ test coverage on critical paths.

## Test Types (all required for production code)

1. **Unit Tests** - individual functions, utilities, components. Fast, isolated, no external deps.
2. **Integration Tests** - API endpoints, database operations, service interactions.
3. **E2E Tests** - critical user flows. Use Playwright (web), pytest (API), or framework-specific tools.

## TDD Workflow (mandatory for new features)

1. **RED** - Write test first. Run it. It must FAIL.
2. **GREEN** - Write minimal implementation to make test pass.
3. **IMPROVE** - Refactor code while keeping tests green.
4. Verify coverage >= 80%.

## Test Structure

### Python (pytest)
```
tests/
  conftest.py           # Shared fixtures
  unit/
    test_models.py
    test_utils.py
  integration/
    test_api.py
    test_database.py
  e2e/
    test_workflows.py
```

### JavaScript/TypeScript (Jest/Vitest)
```
tests/  or  __tests__/
  unit/
    utils.test.ts
    components.test.tsx
  integration/
    api.test.ts
  e2e/
    workflows.spec.ts
```

## Test Principles

- AAA pattern: Arrange, Act, Assert
- One assertion per test (where practical)
- Test behavior, not implementation
- Use factories/fixtures for test data, not hardcoded values
- Mock external services (APIs, databases in unit tests)
- Never test private methods directly
- Fix implementation when tests fail, not tests (unless test is wrong)
- Tests must be deterministic: no random data, no time-dependent logic without mocking

## What to Test

- Happy path (expected inputs produce expected outputs)
- Edge cases (empty inputs, boundary values, null/None)
- Error handling (invalid inputs, network failures, timeouts)
- Security-critical paths (auth, permissions, input validation)
- Business logic (calculations, state transitions, rules)

## Framework-Specific Commands

```bash
# Python
pytest --cov=src --cov-report=term-missing -v

# JavaScript/TypeScript
npm test -- --coverage
npx vitest run --coverage

# E2E
npx playwright test
pytest tests/e2e/ -v
```
