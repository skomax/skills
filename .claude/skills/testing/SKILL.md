---
name: testing
description: Testing patterns for Python (pytest) and JavaScript/TypeScript (Jest, Vitest, Playwright). TDD workflow, fixtures, mocking, E2E testing.
---

# Testing Skill

## When to Activate
- Writing or reviewing tests
- Setting up testing infrastructure
- Implementing TDD workflow
- Creating fixtures and mocks
- Running E2E tests

## Python Testing (pytest)

### Configuration
```toml
# pyproject.toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--cov=src --cov-report=term-missing -v --tb=short"
asyncio_mode = "auto"
markers = [
    "slow: marks tests as slow",
    "integration: marks integration tests",
    "e2e: marks end-to-end tests",
]
```

### Fixtures (conftest.py)
```python
import pytest
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

@pytest.fixture
async def db_session():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    async with AsyncSession(engine) as session:
        yield session
    await engine.dispose()

@pytest.fixture
async def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client
    app.dependency_overrides.clear()

@pytest.fixture
def sample_user():
    return {"email": "test@example.com", "name": "Test User", "password": "SecurePass123"}
```

### Unit Tests
```python
class TestPriceCalculation:
    def test_tick_to_price_conversion(self):
        tick = 202919
        price = tick_to_price(tick, decimals0=6, decimals1=18)
        assert 1900 < price < 2100  # ETH/USDC range

    def test_fee_calculation_in_range(self):
        fees = calculate_fees(liquidity=1000000, tick_lower=100, tick_upper=200, current_tick=150)
        assert fees[0] >= 0
        assert fees[1] >= 0

    def test_invalid_tick_range_raises(self):
        with pytest.raises(ValueError, match="lower must be less than upper"):
            validate_tick_range(lower=200, upper=100)
```

### Integration Tests
```python
class TestUserAPI:
    async def test_create_user(self, client, sample_user):
        response = await client.post("/api/v1/users", json=sample_user)
        assert response.status_code == 201
        data = response.json()
        assert data["email"] == sample_user["email"]

    async def test_create_duplicate_user(self, client, sample_user):
        await client.post("/api/v1/users", json=sample_user)
        response = await client.post("/api/v1/users", json=sample_user)
        assert response.status_code == 409

    async def test_login_returns_token(self, client, sample_user):
        await client.post("/api/v1/users", json=sample_user)
        response = await client.post("/api/v1/auth/login", json={
            "email": sample_user["email"], "password": sample_user["password"]
        })
        assert response.status_code == 200
        assert "access_token" in response.json()
```

### Parametrize (test multiple inputs concisely)
```python
import pytest

@pytest.mark.parametrize("input_val, expected", [
    ("hello", 5),
    ("", 0),
    ("a" * 1000, 1000),
    ("unicode: \u2603", 10),
])
def test_string_length(input_val, expected):
    assert len(input_val) == expected

# Parametrize with IDs for readable output
@pytest.mark.parametrize("status_code, should_retry", [
    pytest.param(200, False, id="success"),
    pytest.param(429, True, id="rate-limited"),
    pytest.param(500, True, id="server-error"),
    pytest.param(404, False, id="not-found"),
])
def test_retry_logic(status_code, should_retry):
    assert should_retry_request(status_code) == should_retry
```

### Fixture Parametrization
```python
@pytest.fixture(params=["sqlite+aiosqlite:///:memory:", "postgresql+asyncpg://test:test@localhost/test_db"],
                ids=["sqlite", "postgres"])
async def db_engine(request):
    """Run tests against both SQLite and PostgreSQL."""
    engine = create_async_engine(request.param)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield engine
    await engine.dispose()
```

### Mocking
```python
from unittest.mock import AsyncMock, patch

async def test_external_api_failure(self, client):
    with patch("app.services.external_api.fetch", new_callable=AsyncMock) as mock:
        mock.side_effect = httpx.TimeoutException("timeout")
        response = await client.get("/api/v1/data")
        assert response.status_code == 503

async def test_external_api_success(self, client):
    with patch("app.services.external_api.fetch", new_callable=AsyncMock) as mock:
        mock.return_value = {"data": "test"}
        response = await client.get("/api/v1/data")
        assert response.status_code == 200
        assert response.json()["data"] == "test"
```

### Test Factories (factory_boy)
```python
import factory
from factory.alchemy import SQLAlchemyModelFactory

class UserFactory(SQLAlchemyModelFactory):
    class Meta:
        model = User
        sqlalchemy_session_persistence = "commit"

    email = factory.Sequence(lambda n: f"user{n}@example.com")
    name = factory.Faker("name")
    is_active = True

# Usage in tests:
# user = UserFactory(session=db_session)
# users = UserFactory.create_batch(10, session=db_session)
```

## JavaScript/TypeScript Testing

### Vitest Configuration
```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      thresholds: { lines: 80, functions: 80, branches: 80 },
    },
  },
})
```

### Component Testing
```tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { SearchBar } from './search-bar'

describe('SearchBar', () => {
  it('calls onSearch with input value', async () => {
    const onSearch = vi.fn()
    render(<SearchBar onSearch={onSearch} />)

    await fireEvent.change(screen.getByPlaceholderText('Search...'), {
      target: { value: 'test query' },
    })
    await fireEvent.click(screen.getByText('Search'))

    expect(onSearch).toHaveBeenCalledWith('test query')
  })
})
```

## E2E Testing (Playwright)

```typescript
import { test, expect } from '@playwright/test'

test('user can login and see dashboard', async ({ page }) => {
  await page.goto('/login')
  await page.fill('[name="email"]', 'admin@example.com')
  await page.fill('[name="password"]', 'password123')
  await page.click('button[type="submit"]')

  await expect(page).toHaveURL('/dashboard')
  await expect(page.getByText('Welcome')).toBeVisible()
})
```

## TDD Checklist

1. Write failing test for the feature
2. Run test - confirm it fails (RED)
3. Write minimal code to pass
4. Run test - confirm it passes (GREEN)
5. Refactor while tests stay green (REFACTOR)
6. Check coverage meets project threshold

## Running Tests

```bash
# Python - with coverage
pytest --cov=src --cov-report=term-missing -v

# Python - specific markers
pytest -m "not slow" -v
pytest -m integration -v

# Python - specific test/pattern
pytest tests/unit/test_users.py -v
pytest -k "test_login" -v

# JS/TS - Vitest
npx vitest run --coverage
npx vitest run --reporter=verbose

# E2E - Playwright
npx playwright test
npx playwright test --ui  # interactive mode
```

## See Also
- `database-patterns` skill for test DB fixtures
- `fastapi-backend` skill for API test patterns
- `04-testing-rules.md` for project-level testing policy
