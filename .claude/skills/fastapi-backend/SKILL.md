---
name: fastapi-backend
description: FastAPI backend development patterns, project structure, middleware, dependency injection, database integration, and deployment for REST API services.
---

# FastAPI Backend Skill

## When to Activate
- Building REST APIs with FastAPI
- Setting up backend microservices
- Working with SQLAlchemy, Alembic, Pydantic
- API authentication, middleware, background tasks

## Project Structure

```
backend/
  app/
    __init__.py
    main.py              # FastAPI app factory
    config.py            # Settings via pydantic-settings
    dependencies.py      # Shared dependencies
    api/
      __init__.py
      v1/
        __init__.py
        router.py        # API v1 main router
        endpoints/
          users.py
          auth.py
          items.py
    core/
      security.py        # JWT, hashing, auth
      exceptions.py      # Custom exception handlers
    models/
      __init__.py
      user.py            # SQLAlchemy models
      item.py
    schemas/
      __init__.py
      user.py            # Pydantic schemas
      item.py
    services/
      __init__.py
      user_service.py    # Business logic
    db/
      __init__.py
      session.py         # Database session
      base.py            # SQLAlchemy base
    workers/
      __init__.py
      tasks.py           # Background/Celery tasks
  alembic/
    versions/
    env.py
  alembic.ini
  tests/
  pyproject.toml
  Dockerfile
```

## Core Patterns

### App Factory
```python
from fastapi import FastAPI
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    yield
    # Shutdown
    await close_db()

def create_app() -> FastAPI:
    app = FastAPI(
        title="My API",
        version="1.0.0",
        lifespan=lifespan,
    )
    app.include_router(api_v1_router, prefix="/api/v1")
    app.add_middleware(CORSMiddleware, allow_origins=settings.ALLOWED_ORIGINS)
    return app

app = create_app()
```

### Pydantic Schemas (Request/Response)
```python
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=1, max_length=100)

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime
    model_config = {"from_attributes": True}

class PaginatedResponse(BaseModel):
    items: list[UserResponse]
    total: int
    page: int
    size: int
```

### Dependency Injection
```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    payload = verify_jwt(token)
    user = await db.get(User, payload["sub"])
    if not user:
        raise HTTPException(401, "User not found")
    return user

@router.get("/me", response_model=UserResponse)
async def get_me(user: User = Depends(get_current_user)):
    return user
```

### CRUD Endpoints
```python
@router.get("/", response_model=PaginatedResponse)
async def list_items(
    page: int = Query(1, ge=1),
    size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    total = await db.scalar(select(func.count(Item.id)))
    items = await db.scalars(
        select(Item).offset((page - 1) * size).limit(size)
    )
    return PaginatedResponse(items=items.all(), total=total, page=page, size=size)

@router.post("/", response_model=ItemResponse, status_code=201)
async def create_item(
    data: ItemCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    item = Item(**data.model_dump(), owner_id=user.id)
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item
```

### Background Tasks
```python
from fastapi import BackgroundTasks

@router.post("/send-report")
async def send_report(
    background_tasks: BackgroundTasks,
    user: User = Depends(get_current_user),
):
    background_tasks.add_task(generate_and_email_report, user.email)
    return {"message": "Report generation started"}
```

### Error Handling
```python
from fastapi import HTTPException
from fastapi.responses import JSONResponse

class AppException(Exception):
    def __init__(self, status_code: int, detail: str):
        self.status_code = status_code
        self.detail = detail

@app.exception_handler(AppException)
async def app_exception_handler(request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"success": False, "error": exc.detail},
    )
```

## Database (SQLAlchemy Async)

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, DeclarativeBase

engine = create_async_engine(settings.DATABASE_URL, pool_size=20, max_overflow=10)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

class Base(DeclarativeBase):
    pass
```

## Alembic Migrations
```bash
# Create migration
alembic revision --autogenerate -m "add users table"
# Apply migrations
alembic upgrade head
# Rollback
alembic downgrade -1
```

## Docker Deployment
```dockerfile
FROM python:3.12-slim AS production
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
```

## Key Dependencies
| Package | Purpose |
|---------|---------|
| fastapi | Web framework |
| uvicorn | ASGI server |
| pydantic-settings | Config from env |
| sqlalchemy[asyncio] | Async ORM |
| alembic | Migrations |
| python-jose | JWT tokens |
| passlib[bcrypt] | Password hashing |
| httpx | Async HTTP client |
| celery | Task queue |
| redis | Cache + broker |
