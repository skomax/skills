# Skills & Rules Improvement Plan

## Verification Sources
All changes verified against context7 (latest docs as of March 2026):
- aiogram v3.25.0 (v4.1 exists)
- FastAPI 0.128.0
- Next.js v16.1.6 (skill says 15 - outdated!)
- SQLAlchemy 2.1
- Rails 8.0 (Solid Queue/Cache/Cable confirmed)
- Anthropic SDK: AsyncAnthropic + tool_use patterns
- web3.py: AsyncWeb3 + AsyncHTTPProvider
- Tailwind CSS v4: CSS-based config (@import "tailwindcss"), no tailwind.config.js
- discord.py 2.x: hybrid commands, comprehensive error handling
- pytest: parametrize, fixture params, marks

---

## Phase 1: Critical Bug Fixes (async/sync, deprecated APIs)
**Priority: CRITICAL | Impact: Code from skills will crash in production**

### 1.1 Fix async/sync mixing (3 skills)

#### document-processing/SKILL.md
- **Bug**: `LLMExtractor` uses `async def` but calls sync `anthropic.Anthropic()`
- **Fix**: Change to `AsyncAnthropic` + `await client.messages.create()`
- **Verified**: context7 confirms `AsyncAnthropic` is the correct async client
- **Also**: Add `json.loads()` error handling for LLM output (wrap in try/except)

#### saas-platform/SKILL.md
- **Bug**: `XPoster.post()` is `async def` but calls sync `tweepy.Client.create_tweet()`
- **Fix**: Use `asyncio.to_thread(client.create_tweet, ...)` wrapper or switch to async HTTP lib (httpx)
- **Also**: Remove duplicate Twitter/X class (XClient duplicates XPoster)

#### web3-defi/SKILL.md
- **Bug**: `get_pool_data()` is `async def` but uses sync `Web3.HTTPProvider`
- **Fix**: Change to `AsyncWeb3(AsyncWeb3.AsyncHTTPProvider(url))`
- **Verified**: context7 confirms `AsyncWeb3` + `AsyncHTTPProvider` pattern
- **Also**: Fix price calculation to include token decimals

### 1.2 Fix deprecated Python APIs (2 skills)

#### python-development/SKILL.md
- `datetime.utcnow()` -> `datetime.now(timezone.utc)` (deprecated since Python 3.12)

#### saas-platform/SKILL.md
- Same `datetime.utcnow()` fix

### 1.3 Fix deprecated library recommendations (2 skills)

#### fastapi-backend/SKILL.md
- Replace `python-jose` -> `PyJWT` or `joserfc` (python-jose unmaintained)
- Replace `passlib[bcrypt]` -> `bcrypt` directly or `argon2-cffi` (passlib unmaintained since 2022)
- Replace `sessionmaker` -> `async_sessionmaker` from `sqlalchemy.ext.asyncio`
- **Verified**: context7 confirms `async_sessionmaker` is the correct SQLAlchemy 2.x pattern

#### ruby-on-rails/SKILL.md
- Replace `bundle install --without development test` -> `bundle config set --local without 'development test' && bundle install`

---

## Phase 2: Outdated Version & Pattern Updates
**Priority: HIGH | Impact: Skills teach old patterns, devs learn wrong approaches**

### 2.1 Next.js: 15 -> 16 + missing critical features

#### nextjs-frontend/SKILL.md
- **Version**: Update from Next.js 15 to 16.x (context7 shows v16.1.6)
- **Add Server Actions**: Major feature, completely missing
  ```tsx
  async function createItem(formData: FormData) {
    'use server'
    // mutate data
    revalidatePath('/items')
  }
  ```
- **Add Middleware**: Missing, needed for auth/redirects/i18n
- **Add loading.tsx/error.tsx**: Standard App Router patterns
- **Add Metadata API**: `export const metadata` / `generateMetadata()`
- **Tailwind v4 config change**: Mention `@import "tailwindcss"` instead of `tailwind.config.js`
  - **Verified**: context7 confirms v4 uses CSS-based config, `@tailwind` directives removed
- **Remove**: Prisma-looking `db.items.create({ data })` in API route (Prisma not in stack)

### 2.2 SQLAlchemy: Update patterns across skills

#### database-patterns/SKILL.md
- Add `async_sessionmaker` pattern (currently only shows sync sessionmaker)
- Add `AsyncAttrs` mixin to `DeclarativeBase` for async attribute access:
  ```python
  class Base(AsyncAttrs, DeclarativeBase):
      pass
  ```
- Fix redundant index on `users(email)` (UNIQUE already creates index)
- Add BIGSERIAL example (mentioned but never shown)
- **Verified**: context7 shows SQLAlchemy 2.1 patterns with `async_sessionmaker` + `AsyncAttrs`

### 2.3 Rails 8: Add actual Rails 8 features

#### ruby-on-rails/SKILL.md
- **Add Solid Queue**: Default job backend in Rails 8, replaces Sidekiq/Redis
  ```ruby
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  ```
- **Add Solid Cache**: Default cache store, replaces Redis/Memcached
  ```ruby
  config.cache_store = :solid_cache_store
  ```
- **Add Solid Cable**: Default Action Cable adapter (DB-backed)
- **Add Kamal 2**: Default deployment tool for Rails 8
- **Add Propshaft**: Default asset pipeline (replaces Sprockets)
- **Verified**: context7 confirms all Solid * features as defaults in Rails 8.0

### 2.4 Discord.py: Add hybrid commands + comprehensive error handling

#### discord-bot/SKILL.md
- **Add hybrid commands**: Major pattern missing
  ```python
  @bot.hybrid_command(name='ping', description='Check latency')
  async def ping(ctx):
      await ctx.send(f'Pong! {round(bot.latency * 1000)}ms')
  ```
- **Expand error handler**: Currently only handles 2 types, should handle:
  CommandNotFound, MissingPermissions, MissingRequiredArgument, BadArgument, CommandOnCooldown, CheckFailure
- **Verified**: context7 confirms hybrid commands and comprehensive error patterns
- **Expand discord.js section or remove**: Currently skeletal, misleading

### 2.5 Anthropic SDK: Fix patterns + add tool_use

#### prompt-engineering/SKILL.md
- Add `tool_use` for reliable structured output (instead of raw JSON parsing)
- Add prompt caching (major cost optimization, not mentioned at all)
- Add actual chain-of-thought examples (claimed in description but missing)
- Add few-shot examples (same)
- Update model IDs if needed

#### document-processing/SKILL.md
- Fix all sync -> async patterns (see Phase 1)
- Add `tool_use` for structured extraction instead of raw JSON parsing

### 2.6 web3.py: Fix async patterns

#### web3-defi/SKILL.md
- Use `AsyncWeb3` throughout (see Phase 1)
- Complete the fee calculation (currently `# ... handle other cases`)
- Fix impermanent loss note: formula is for x*y=k, not concentrated liquidity (IL is amplified in v3)
- Fix `iterrows()` usage (contradicts data-processing skill's own advice)

### 2.7 aiogram: Verify patterns are current

#### telegram-bot/SKILL.md
- aiogram is at v3.25.0 (even v4.1 beta exists) - update version mention
- Webhook pattern is mostly correct per context7, minor cleanups
- Add warning about Telethon AccountPool (Telegram ToS risk)
- Remove python-telegram-bot from framework table or add code examples

### 2.8 Python tooling updates

#### python-development/SKILL.md
- Consolidate ruff recommendation: ruff replaces black + isort + flake8, no need for all three
- Update ruff config: `[tool.ruff]` -> `[tool.ruff.lint]` for lint settings
- Replace `aiohttp` example with `httpx` (more modern, recommended for new projects)
- Add `uv` as project manager (not just dep manager)
- Fix `asyncio.gather` example: coroutines vs tasks distinction

---

## Phase 3: Structural Improvements
**Priority: MEDIUM | Impact: Better maintainability and usability**

### 3.1 Split saas-platform into focused skills
Current: ~675 lines covering architecture + social media + monitoring + scheduling + RSS

Split into:
- `saas-platform/SKILL.md` - Architecture, orchestrator pattern, multi-tenant middleware (~200 lines)
- `social-media-integration/SKILL.md` - Twitter/X, Telegram, Instagram APIs (~200 lines)
- `monitoring/SKILL.md` - Prometheus, Grafana, alerting (~150 lines)

### 3.2 Expand testing skill
Current: ~175 lines, too thin for the most universally needed skill

Add:
- `@pytest.mark.parametrize` with examples (context7 confirmed patterns)
- Fixture parametrization with `params` and `ids`
- Property-based testing with Hypothesis
- Test factories (factory_boy)
- Generic examples instead of domain-specific (tick_to_price etc.)
- CI integration patterns
- Rename "IMPROVE" -> "REFACTOR" (standard TDD terminology)

### 3.3 Add cross-references between skills
Add "See also" sections:
- `fastapi-backend` -> `database-patterns`, `docker-devops`, `testing`
- `web3-defi` -> `database-patterns`, `data-processing`
- `telegram-bot` -> `docker-devops`, `database-patterns`
- `nextjs-frontend` -> `testing`
- `saas-platform` -> `docker-devops`, `monitoring`

### 3.4 Fix rules activation scope
- `05-security-rules.md`: Change `paths: ["**/*"]` to specific code patterns (`*.py`, `*.js`, `*.ts`, `*.sol`, `Dockerfile*`, `*.yaml`)
- `02-git-workflow.md`: Consider moving core git rules to CLAUDE.md (always loaded anyway), keep only detailed patterns in rule file
- `06-documentation-rules.md`: Add code file patterns so it triggers when code changes (not just when editing .md)

### 3.5 Remove duplication across files
- SQLAlchemy setup: Keep full version in `database-patterns`, reference from `fastapi-backend`
- Dockerfiles: Keep full version in `docker-devops`, reference from other skills
- 80% coverage: Define once in `04-testing-rules.md`, reference from commands

---

## Phase 4: Command Improvements
**Priority: MEDIUM | Impact: Commands become actually useful instead of generic templates**

### 4.1 Add $ARGUMENTS to commands
- `test/run.md`: Accept test path/pattern (`$ARGUMENTS` -> specific test file)
- `dev/debug.md`: Accept error message or file path
- `dev/code-review.md`: Accept commit range or branch name
- `deploy/docker-rebuild.md`: Accept specific service name

### 4.2 Fix git diff patterns
- Replace `HEAD~1` with `main...HEAD` in:
  - `dev/code-review.md`
  - `deploy/docker-rebuild.md`
- Or use `$ARGUMENTS` to accept a custom range

### 4.3 Fix deploy/prod.md
- Make deployment step concrete (not just "deploy with zero-downtime strategy")
- Align rollback procedure with CI-based deployment flow
- Remove mixed Python/Ruby/Node references - detect project type first

### 4.4 Fix project/init.md
- Add data-processing template (listed as option but no template)
- Align dependency management (all Python templates should use pyproject.toml, not mix with requirements.txt)
- Add pre-commit hooks, CI config, Makefile generation

### 4.5 Fix project/status.md
- Add actual commands for dependency check section (currently empty)
- Add project type detection (like test/run.md does)
- Define thresholds for GOOD/WARN/FAIL ratings

### 4.6 Add cross-references between commands
- `deploy/prod.md` -> references `test/run.md` for test step
- `dev/debug.md` Phase 4 -> references `dev/tdd.md` for test-first fix
- `dev/refactor.md` -> references `test/run.md` for coverage check

---

## Phase 5: Missing Content
**Priority: LOW | Impact: Coverage of gaps, nice-to-have**

### 5.1 Add missing imports to all code examples
Systematic pass through all skills:
- `discord-bot`: Add `import asyncio`
- `fastapi-backend`: Add `from collections.abc import AsyncGenerator`
- `document-processing`: Add `from dataclasses import field`
- All skills: Verify every code block has necessary imports

### 5.2 Add "last verified" date to version-pinned skills
Skills that pin specific versions should include:
```
<!-- Last verified: 2026-03-05 -->
```
- `docker-devops` (Grafana 10.4.0, Prometheus v2.51.0)
- `saas-platform` (Instagram API v21.0)
- All skills with framework version numbers

### 5.3 Expand data-processing skill
- Add Dask code examples (mentioned but zero examples)
- Add Apache Arrow backend mention (pandas 2.x major feature)
- Fix `optimize_dtypes` in-place mutation pattern
- Fix `assert` in ETL validation -> `raise ValueError`
- Define `risk_free` variable in Sharpe ratio

### 5.4 Expand mcp-servers skill
- Update MCP SDK import paths (may have changed)
- Add SSE transport option
- Add debugging/logging guidance
- Resolve .claude/ gitignore contradiction

---

## Execution Order

| Order | Phase | Est. Files Changed | Description |
|-------|-------|-------------------|-------------|
| 1 | 1.1 | 3 skills | Fix async/sync bugs (CRITICAL) |
| 2 | 1.2-1.3 | 4 skills | Fix deprecated APIs & libs |
| 3 | 2.1 | 1 skill | Next.js 16 + Server Actions + Tailwind v4 |
| 4 | 2.2 | 1 skill | SQLAlchemy 2.1 patterns |
| 5 | 2.3 | 1 skill | Rails 8 Solid * features |
| 6 | 2.4 | 1 skill | Discord.py hybrid + errors |
| 7 | 2.5-2.6 | 3 skills | Anthropic SDK + web3.py fixes |
| 8 | 2.7-2.8 | 2 skills | aiogram + Python tooling |
| 9 | 3.1 | 1 skill -> 3 | Split saas-platform |
| 10 | 3.2 | 1 skill | Expand testing |
| 11 | 3.3-3.5 | ~10 files | Cross-refs, rules, dedup |
| 12 | 4.1-4.6 | 10 commands | Command improvements |
| 13 | 5.1-5.4 | ~15 files | Missing content, imports, dates |

**Total: ~40 files touched across 13 steps**
