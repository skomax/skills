---
name: database-patterns
description: PostgreSQL, Redis, SQLAlchemy async patterns. Migrations, optimization, connection pooling, caching strategies, and data modeling.
---

# Database Patterns Skill

## When to Activate
- Designing database schemas
- Writing queries, migrations
- Optimizing query performance
- Setting up caching with Redis
- Configuring connection pools

## PostgreSQL Patterns

### Schema Design
```sql
-- Always use UUID or BIGSERIAL for PKs
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partial index for common queries (UNIQUE on email already creates an index)
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;

-- BIGSERIAL example for high-throughput tables
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Use TIMESTAMPTZ not TIMESTAMP (timezone-aware)
-- Use JSONB for flexible schemas, not JSON
-- Use TEXT for variable-length strings without max
```

### SQLAlchemy 2.x Async Models
```python
from sqlalchemy import String, Boolean, DateTime, func
from sqlalchemy.ext.asyncio import AsyncAttrs, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from datetime import datetime
import uuid

class Base(AsyncAttrs, DeclarativeBase):
    pass

# Async session factory (use async_sessionmaker, NOT sessionmaker)
engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
async_session = async_sessionmaker(engine, expire_on_commit=False)

class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(100))
    is_active: Mapped[bool] = mapped_column(default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
```

### Query Optimization
```python
# BAD: N+1 query
users = await db.scalars(select(User))
for user in users:
    orders = await db.scalars(select(Order).where(Order.user_id == user.id))

# GOOD: Eager loading
from sqlalchemy.orm import joinedload, selectinload

users = await db.scalars(
    select(User).options(selectinload(User.orders)).where(User.is_active == True)
)

# GOOD: Select only needed columns
result = await db.execute(
    select(User.id, User.name).where(User.is_active == True).limit(20)
)

# GOOD: Use EXISTS instead of COUNT for boolean checks
from sqlalchemy import exists
has_orders = await db.scalar(
    select(exists().where(Order.user_id == user_id))
)
```

### Connection Pool
```python
from sqlalchemy.ext.asyncio import create_async_engine

engine = create_async_engine(
    DATABASE_URL,
    pool_size=20,          # Max persistent connections
    max_overflow=10,       # Extra connections beyond pool_size
    pool_timeout=30,       # Seconds to wait for connection
    pool_recycle=1800,     # Recycle connections after 30min
    pool_pre_ping=True,    # Verify connections before use
)
```

## Redis Patterns

### Caching
```python
import redis.asyncio as redis
import json

class Cache:
    def __init__(self, url: str = "redis://localhost:6379"):
        self.redis = redis.from_url(url, decode_responses=True)

    async def get_or_set(self, key: str, factory, ttl: int = 300):
        """Cache-aside pattern."""
        cached = await self.redis.get(key)
        if cached:
            return json.loads(cached)
        value = await factory()
        await self.redis.setex(key, ttl, json.dumps(value, default=str))
        return value

    async def invalidate(self, pattern: str):
        """Invalidate keys matching pattern. Use pipeline for efficiency."""
        keys = [key async for key in self.redis.scan_iter(pattern)]
        if keys:
            async with self.redis.pipeline() as pipe:
                for key in keys:
                    pipe.delete(key)
                await pipe.execute()
```

### Rate Limiting
```python
async def check_rate_limit(redis_client, user_id: str, max_requests: int = 100, window: int = 60) -> bool:
    key = f"rate:{user_id}"
    current = await redis_client.incr(key)
    if current == 1:
        await redis_client.expire(key, window)
    return current <= max_requests
```

### Task Queue (simple)
```python
# Producer
await redis_client.lpush("tasks:parsing", json.dumps({"url": url, "priority": 1}))

# Consumer (worker)
while True:
    _, task_data = await redis_client.brpop("tasks:parsing", timeout=30)
    if task_data:
        task = json.loads(task_data)
        await process_task(task)
```

## Alembic Migrations

```bash
# Initialize
alembic init alembic

# Create migration from model changes
alembic revision --autogenerate -m "add_users_table"

# Apply all pending migrations
alembic upgrade head

# Rollback one step
alembic downgrade -1

# Show current version
alembic current

# Show migration history
alembic history
```

### Migration Best Practices
- Always review auto-generated migrations before applying
- Write both upgrade() and downgrade() functions
- Test migrations on a copy of production data
- Never modify already-applied migrations
- Use data migrations for transforming existing data
- Keep migrations small and focused
