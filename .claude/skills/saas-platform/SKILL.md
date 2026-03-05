---
name: saas-platform
description: SaaS platform architecture with Docker orchestration, workers, task queues, social media integration, content management, and multi-service deployment.
---

# SaaS Platform Skill

## When to Activate
- Building multi-service SaaS applications
- Setting up worker/orchestrator architecture
- Social media integration (posting, parsing, scheduling)
- Content management and automation pipelines
- Multi-tenant application design

## Architecture Pattern: Orchestrator + Workers

```
                    +------------------+
                    |    Dashboard     |
                    |  (Next.js/React) |
                    +--------+---------+
                             |
                    +--------+---------+
                    |    API Gateway    |
                    |    (FastAPI)      |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------+----------+     +-----------+---------+
    |    Orchestrator     |     |      Redis          |
    |  (task scheduling,  |     |  (queue, cache,     |
    |   health checks,    |     |   pub/sub)          |
    |   worker management)|     +---------------------+
    +---------+----------+
              |
    +---------+---------+---------+---------+
    |         |         |         |         |
+---+---+ +--+----+ +--+----+ +--+----+ +--+----+
|Parser | |Poster | |Content| |Monitor| |Export |
|Worker | |Worker | |Worker | |Worker | |Worker |
+-------+ +-------+ +-------+ +-------+ +-------+
```

## Docker Compose for SaaS

```yaml
services:
  # API Gateway
  api:
    build:
      context: .
      target: production
    ports:
      - "8000:8000"
    env_file: .env
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
    restart: always
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  # Frontend Dashboard
  dashboard:
    build:
      context: ./frontend
      target: production
    ports:
      - "3000:3000"
    depends_on:
      - api
    restart: always

  # Orchestrator - manages all workers
  orchestrator:
    build: .
    command: python -m app.orchestrator.main
    env_file: .env
    depends_on:
      db: { condition: service_healthy }
      redis: { condition: service_started }
    restart: always
    healthcheck:
      test: ["CMD", "python", "-m", "app.orchestrator.healthcheck"]
      interval: 60s

  # Workers
  worker-parser:
    build: .
    command: celery -A app.workers.parser worker -l info -Q parsing
    env_file: .env
    deploy:
      replicas: 2
    depends_on:
      - redis
    restart: always

  worker-poster:
    build: .
    command: celery -A app.workers.poster worker -l info -Q posting
    env_file: .env
    depends_on:
      - redis
    restart: always

  worker-content:
    build: .
    command: celery -A app.workers.content worker -l info -Q content
    env_file: .env
    depends_on:
      - redis
    restart: always

  # Scheduler (Celery Beat)
  scheduler:
    build: .
    command: celery -A app.celery_app beat -l info
    env_file: .env
    depends_on:
      - redis
    restart: always

  # Infrastructure
  db:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: saas_db
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 5s

  redis:
    image: redis:7-alpine
    volumes:
      - redisdata:/data

volumes:
  pgdata:
  redisdata:
```

## Orchestrator Pattern

```python
import asyncio
from datetime import datetime

class Orchestrator:
    def __init__(self, redis_client, db_session):
        self.redis = redis_client
        self.db = db_session
        self.workers = {}

    async def run(self):
        """Main orchestrator loop."""
        await self.register_workers()
        while True:
            await self.health_check_workers()
            await self.schedule_pending_tasks()
            await self.process_failed_tasks()
            await self.cleanup_stale_jobs()
            await asyncio.sleep(30)

    async def health_check_workers(self):
        """Check all workers are alive and responsive."""
        for name, worker in self.workers.items():
            last_heartbeat = await self.redis.get(f"worker:{name}:heartbeat")
            if not last_heartbeat or (datetime.utcnow() - last_heartbeat).seconds > 120:
                await self.restart_worker(name)
                await self.alert(f"Worker {name} restarted due to missed heartbeat")

    async def schedule_pending_tasks(self):
        """Dispatch scheduled tasks to appropriate queues."""
        tasks = await self.db.get_pending_tasks()
        for task in tasks:
            queue = self.get_queue_for_task(task.type)
            await self.redis.lpush(queue, task.serialize())
            await self.db.mark_task_dispatched(task.id)
```

## Social Media Integration

### Twitter/X Posting
```python
import tweepy

class XPoster:
    def __init__(self, api_key, api_secret, access_token, access_secret):
        auth = tweepy.OAuthHandler(api_key, api_secret)
        auth.set_access_token(access_token, access_secret)
        self.client = tweepy.Client(
            consumer_key=api_key, consumer_secret=api_secret,
            access_token=access_token, access_token_secret=access_secret
        )

    async def post(self, text: str, media_ids: list[str] | None = None):
        return self.client.create_tweet(text=text, media_ids=media_ids)
```

### Telegram Channel Posting
```python
from aiogram import Bot

class TelegramPoster:
    def __init__(self, bot_token: str):
        self.bot = Bot(token=bot_token)

    async def post_to_channel(self, channel_id: str, text: str, photo_url: str | None = None):
        if photo_url:
            await self.bot.send_photo(channel_id, photo=photo_url, caption=text)
        else:
            await self.bot.send_message(channel_id, text, parse_mode="HTML")
```

### Content Parser Worker
```python
class ContentParser:
    def __init__(self, sources: list[Source]):
        self.sources = sources

    async def parse_all(self) -> list[ContentItem]:
        tasks = [self.parse_source(s) for s in self.sources]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        return [item for result in results if not isinstance(result, Exception) for item in result]

    async def parse_source(self, source: Source) -> list[ContentItem]:
        if source.type == "rss":
            return await self.parse_rss(source.url)
        elif source.type == "telegram":
            return await self.parse_telegram_channel(source.channel_id)
        elif source.type == "twitter":
            return await self.parse_twitter_feed(source.user_id)
```

## Multi-Tenant Design

```python
# Middleware for tenant isolation
class TenantMiddleware:
    async def __call__(self, request, call_next):
        tenant_id = request.headers.get("X-Tenant-ID")
        if not tenant_id:
            tenant_id = await self.resolve_from_domain(request.url.hostname)
        request.state.tenant_id = tenant_id
        response = await call_next(request)
        return response

# All DB queries filtered by tenant
async def get_user_channels(db: AsyncSession, tenant_id: str):
    return await db.scalars(
        select(Channel).where(Channel.tenant_id == tenant_id)
    )
```

## Twitter/X API v2 Integration

### Full Poster with Media
```python
import tweepy
import httpx

class XClient:
    def __init__(self, api_key, api_secret, access_token, access_secret, bearer_token):
        self.client = tweepy.Client(
            bearer_token=bearer_token,
            consumer_key=api_key, consumer_secret=api_secret,
            access_token=access_token, access_token_secret=access_secret,
        )
        # v1.1 API needed for media upload
        auth = tweepy.OAuthHandler(api_key, api_secret)
        auth.set_access_token(access_token, access_secret)
        self.api_v1 = tweepy.API(auth)

    async def post_tweet(self, text: str, media_paths: list[str] | None = None) -> dict:
        media_ids = []
        if media_paths:
            for path in media_paths:
                media = self.api_v1.media_upload(path)
                media_ids.append(media.media_id)

        response = self.client.create_tweet(
            text=text,
            media_ids=media_ids if media_ids else None,
        )
        return {"id": response.data["id"], "text": text}

    async def post_thread(self, tweets: list[str]) -> list[dict]:
        """Post a thread (chain of replies)."""
        results = []
        reply_to = None
        for text in tweets:
            response = self.client.create_tweet(
                text=text,
                in_reply_to_tweet_id=reply_to,
            )
            reply_to = response.data["id"]
            results.append({"id": reply_to, "text": text})
        return results

    async def get_user_tweets(self, username: str, max_results: int = 10) -> list:
        user = self.client.get_user(username=username)
        tweets = self.client.get_users_tweets(
            user.data.id, max_results=max_results,
            tweet_fields=["created_at", "public_metrics"],
        )
        return [{"text": t.text, "metrics": t.public_metrics} for t in tweets.data]
```

### Content Scheduling Engine
```python
from datetime import datetime, timezone
from enum import Enum

class PostStatus(Enum):
    PENDING = "pending"
    SCHEDULED = "scheduled"
    POSTED = "posted"
    FAILED = "failed"
    CANCELLED = "cancelled"

@dataclass
class ScheduledPost:
    id: str
    platform: str          # twitter | telegram | instagram
    content: str
    media_urls: list[str]
    scheduled_at: datetime
    status: PostStatus = PostStatus.PENDING
    retry_count: int = 0
    max_retries: int = 3
    account_id: str = ""
    error_message: str | None = None

class ContentScheduler:
    def __init__(self, db, redis, posters: dict):
        self.db = db
        self.redis = redis
        self.posters = posters  # {"twitter": XClient, "telegram": TelegramPoster, ...}

    async def schedule(self, post: ScheduledPost):
        """Add post to schedule queue."""
        await self.db.save_post(post)
        score = post.scheduled_at.timestamp()
        await self.redis.zadd("schedule:queue", {post.id: score})

    async def process_due_posts(self):
        """Called by scheduler worker every 30 seconds."""
        now = datetime.now(timezone.utc).timestamp()
        due_ids = await self.redis.zrangebyscore("schedule:queue", 0, now, start=0, num=50)

        for post_id in due_ids:
            post = await self.db.get_post(post_id)
            if post.status == PostStatus.CANCELLED:
                await self.redis.zrem("schedule:queue", post_id)
                continue
            try:
                poster = self.posters[post.platform]
                await poster.post(post.content, post.media_urls)
                post.status = PostStatus.POSTED
            except Exception as e:
                post.retry_count += 1
                if post.retry_count >= post.max_retries:
                    post.status = PostStatus.FAILED
                    post.error_message = str(e)
                else:
                    # Re-schedule with exponential backoff
                    delay = 60 * (2 ** post.retry_count)
                    new_time = now + delay
                    await self.redis.zadd("schedule:queue", {post_id: new_time})
                    continue
            await self.redis.zrem("schedule:queue", post_id)
            await self.db.update_post(post)
```

### RSS/Source Parsing Pipeline
```python
import feedparser
import hashlib

class RSSParser:
    def __init__(self, redis):
        self.redis = redis

    async def parse_feed(self, feed_url: str) -> list[dict]:
        """Parse RSS feed, return only new items."""
        feed = feedparser.parse(feed_url)
        new_items = []

        for entry in feed.entries:
            content_hash = hashlib.md5(entry.link.encode()).hexdigest()
            # Check deduplication
            if await self.redis.sismember("parsed:seen", content_hash):
                continue

            new_items.append({
                "title": entry.title,
                "link": entry.link,
                "summary": entry.get("summary", ""),
                "published": entry.get("published", ""),
                "source": feed_url,
                "hash": content_hash,
            })
            await self.redis.sadd("parsed:seen", content_hash)

        return new_items

class ContentAggregator:
    def __init__(self, parsers: dict, llm_client):
        self.parsers = parsers  # {"rss": RSSParser, "telegram": TGParser, ...}
        self.llm = llm_client

    async def aggregate_and_generate(self, sources: list[Source]) -> list[dict]:
        """Fetch from all sources, deduplicate, generate posts."""
        raw_items = []
        for source in sources:
            parser = self.parsers[source.type]
            items = await parser.parse(source)
            raw_items.extend(items)

        # LLM-based content generation from aggregated sources
        posts = []
        for item in raw_items[:20]:  # Limit per cycle
            generated = await self.llm.generate_post(
                source_text=item["summary"],
                platform=item.get("target_platform", "telegram"),
                tone=item.get("tone", "professional"),
            )
            posts.append(generated)
        return posts
```

## Instagram Graph API Integration

### Setup
```python
import httpx

class InstagramClient:
    BASE_URL = "https://graph.facebook.com/v21.0"

    def __init__(self, access_token: str, ig_user_id: str):
        self.token = access_token
        self.ig_user_id = ig_user_id
        self.http = httpx.AsyncClient(timeout=30)

    async def publish_photo(self, image_url: str, caption: str) -> dict:
        """Two-step publish: create container -> publish."""
        # Step 1: Create media container
        container = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media",
            params={
                "image_url": image_url,  # Must be publicly accessible URL
                "caption": caption,
                "access_token": self.token,
            },
        )
        container_id = container.json()["id"]

        # Step 2: Publish container
        result = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media_publish",
            params={
                "creation_id": container_id,
                "access_token": self.token,
            },
        )
        return result.json()

    async def publish_carousel(self, items: list[dict], caption: str) -> dict:
        """Publish carousel (2-10 images/videos)."""
        children_ids = []
        for item in items:
            child = await self.http.post(
                f"{self.BASE_URL}/{self.ig_user_id}/media",
                params={
                    "image_url": item["url"],
                    "is_carousel_item": True,
                    "access_token": self.token,
                },
            )
            children_ids.append(child.json()["id"])

        # Create carousel container
        container = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media",
            params={
                "caption": caption,
                "media_type": "CAROUSEL",
                "children": ",".join(children_ids),
                "access_token": self.token,
            },
        )
        # Publish
        result = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media_publish",
            params={
                "creation_id": container.json()["id"],
                "access_token": self.token,
            },
        )
        return result.json()

    async def publish_reel(self, video_url: str, caption: str) -> dict:
        """Publish a Reel (short video)."""
        container = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media",
            params={
                "video_url": video_url,
                "caption": caption,
                "media_type": "REELS",
                "access_token": self.token,
            },
        )
        container_id = container.json()["id"]

        # Wait for video processing (poll status)
        while True:
            status = await self.http.get(
                f"{self.BASE_URL}/{container_id}",
                params={"fields": "status_code", "access_token": self.token},
            )
            if status.json()["status_code"] == "FINISHED":
                break
            await asyncio.sleep(5)

        result = await self.http.post(
            f"{self.BASE_URL}/{self.ig_user_id}/media_publish",
            params={"creation_id": container_id, "access_token": self.token},
        )
        return result.json()

    async def get_insights(self, media_id: str) -> dict:
        """Get engagement metrics for a post."""
        result = await self.http.get(
            f"{self.BASE_URL}/{media_id}/insights",
            params={
                "metric": "impressions,reach,engagement,saved",
                "access_token": self.token,
            },
        )
        return {m["name"]: m["values"][0]["value"] for m in result.json()["data"]}
```

### Instagram API Notes
- Requires Facebook Business account + Instagram Professional account
- Token flow: Facebook Login -> Page Token -> IG User ID
- Image URLs must be publicly accessible (use presigned S3 URLs)
- Rate limit: 25 API calls per user per hour for publishing
- Carousel: 2-10 items, all same aspect ratio recommended
- Reels: max 15 min, min 3 sec, 9:16 aspect ratio

## Monitoring & Observability

### Prometheus Metrics
```python
from prometheus_client import Counter, Histogram, Gauge, start_http_server

tasks_processed = Counter("tasks_processed_total", "Tasks processed", ["worker", "status"])
task_duration = Histogram("task_duration_seconds", "Task processing time", ["worker"])
active_workers = Gauge("active_workers", "Currently active workers")
queue_size = Gauge("queue_size", "Items in queue", ["queue_name"])

# In worker:
with task_duration.labels(worker="parser").time():
    result = await process_task(task)
    tasks_processed.labels(worker="parser", status="success").inc()

# Expose metrics endpoint
start_http_server(9090)  # Prometheus scrapes this
```

### Grafana + Prometheus Docker Setup
```yaml
# Add to docker-compose.monitoring.yml
services:
  prometheus:
    image: prom/prometheus:v2.51.0
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    restart: always

  grafana:
    image: grafana/grafana:10.4.0
    volumes:
      - grafana_data:/var/lib/grafana
      - ./monitoring/grafana/provisioning:/etc/grafana/provisioning
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
      GF_USERS_ALLOW_SIGN_UP: "false"
    ports:
      - "3001:3000"
    depends_on:
      - prometheus
    restart: always

volumes:
  prometheus_data:
  grafana_data:
```

### Prometheus Config
```yaml
# monitoring/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "api"
    static_configs:
      - targets: ["api:9090"]

  - job_name: "workers"
    static_configs:
      - targets:
          - "worker-parser:9090"
          - "worker-poster:9090"
          - "worker-content:9090"

  - job_name: "orchestrator"
    static_configs:
      - targets: ["orchestrator:9090"]
```

### Grafana Dashboard Provisioning
```yaml
# monitoring/grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true

# monitoring/grafana/provisioning/dashboards/default.yml
apiVersion: 1
providers:
  - name: Default
    folder: SaaS
    type: file
    options:
      path: /var/lib/grafana/dashboards
```

### Key Dashboard Panels
- **Worker throughput**: `rate(tasks_processed_total[5m])` per worker
- **Task latency P95**: `histogram_quantile(0.95, rate(task_duration_seconds_bucket[5m]))`
- **Queue depth**: `queue_size` per queue name
- **Error rate**: `rate(tasks_processed_total{status="error"}[5m]) / rate(tasks_processed_total[5m])`
- **Active workers**: `active_workers` gauge with alert < expected count

## Key Principles

- Each worker handles ONE type of task
- Workers are stateless and horizontally scalable
- Use Redis for inter-service communication (queues, pub/sub)
- Orchestrator monitors health and restarts failed workers
- All configuration via environment variables
- Separate Docker images for API, workers, scheduler
- Use database for persistent state, Redis for ephemeral state
- Implement dead letter queue for permanently failed tasks
- Use content hashing for deduplication across sources
- Rate limit per-platform (X: 50 tweets/day, TG: 20 msgs/min per channel)
