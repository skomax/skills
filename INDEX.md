# Claude Code Skills & Rules - Index

## Quick Start

```bash
# Clone this repo
git clone git@github.com:YOUR_USERNAME/claude-code-skills.git

# Install to your project
cd claude-code-skills
./install.sh /path/to/your/project

# Or copy manually
cp -r .claude/ /path/to/your/project/
cp CLAUDE.md /path/to/your/project/
```

## Structure Overview

```
.
├── CLAUDE.md                          # Master config (framework guide, workflow)
├── INDEX.md                           # This file
├── install.sh                         # Installation script
│
├── .claude/
│   ├── rules/                         # Auto-loaded rules (6 files)
│   │   ├── 01-core-development.md     # Coding standards, project structure, framework selection
│   │   ├── 02-git-workflow.md         # Commits, branches, PRs, versioning
│   │   ├── 03-docker-rules.md        # Docker dev/prod, rebuild triggers, compose patterns
│   │   ├── 04-testing-rules.md       # TDD, coverage 80%+, test types
│   │   ├── 05-security-rules.md      # Secrets, validation, OWASP, Web3 security
│   │   └── 06-documentation-rules.md # Project docs, CHANGELOG, CLAUDE.md management
│   │
│   ├── skills/                        # Context-activated skills (15 skills)
│   │   ├── python-development/        # Python 3.10+, async, type hints, tooling
│   │   ├── fastapi-backend/           # FastAPI, SQLAlchemy, Alembic, auth, CRUD
│   │   ├── nextjs-frontend/           # Next.js 15, React 19, Tailwind 4, shadcn/ui
│   │   ├── ruby-on-rails/            # Rails 8, Hotwire, Stimulus, RSpec     [NEW]
│   │   ├── docker-devops/             # Dockerfile, compose, CI/CD, multi-stage builds
│   │   ├── telegram-bot/              # aiogram 3.x, Telethon, Pyrogram, Mini Apps [EXPANDED]
│   │   ├── discord-bot/               # discord.py 2.x, discord.js 14.x, cogs
│   │   ├── web3-defi/                 # Uniswap v3/v4 hooks, rebalancing, multi-chain [EXPANDED]
│   │   ├── saas-platform/             # X API, scheduling, RSS parsing, monitoring [EXPANDED]
│   │   ├── document-processing/       # OCR engines, PDF parsing, SAP RFC, validation [EXPANDED]
│   │   ├── data-processing/           # pandas, numpy, polars, Dask, ETL pipelines  [NEW]
│   │   ├── database-patterns/         # PostgreSQL, Redis, SQLAlchemy async, migrations
│   │   ├── testing/                   # pytest, Jest, Vitest, Playwright, TDD
│   │   ├── prompt-engineering/        # LLM prompts, structured output, model selection
│   │   └── mcp-servers/              # MCP config, security vetting, custom servers  [NEW]
│   │
│   └── commands/                      # Slash commands (10 commands)
│       ├── dev/
│       │   ├── code-review.md         # /dev:code-review
│       │   ├── plan.md                # /dev:plan
│       │   ├── tdd.md                 # /dev:tdd
│       │   ├── debug.md              # /dev:debug                              [NEW]
│       │   └── refactor.md           # /dev:refactor                           [NEW]
│       ├── test/
│       │   └── run.md                # /test:run                               [NEW]
│       ├── project/
│       │   ├── init.md                # /project:init
│       │   └── status.md             # /project:status                         [NEW]
│       └── deploy/
│           ├── docker-rebuild.md      # /deploy:docker-rebuild
│           └── prod.md               # /deploy:prod                            [NEW]
│
└── research/                          # Research materials (not installed to projects)
```

## Rules (6) - Always Active by File Type

| Rule | Activates On | Key Points |
|------|-------------|------------|
| 01-core-development | *.py, *.js, *.ts, *.tsx, *.sol | Workflow, coding standards, framework selection |
| 02-git-workflow | All files | Conventional commits, branches, PR flow |
| 03-docker-rules | Dockerfile*, docker-compose* | Rebuild triggers, dev/prod separation |
| 04-testing-rules | Test files, config | TDD, 80% coverage, test structure |
| 05-security-rules | All files | Secrets, OWASP, Web3 security |
| 06-documentation-rules | *.md, docs/ | CLAUDE.md, CHANGELOG, ADRs |

## Skills (15) - Activated by Context

| Skill | Domain | Key Content |
|-------|--------|-------------|
| python-development | Python code | Async, type hints, project setup, tooling |
| fastapi-backend | REST APIs | SQLAlchemy, Alembic, auth, CRUD, middleware |
| nextjs-frontend | Web frontend | App Router, Server Components, shadcn/ui |
| ruby-on-rails | Rails web apps | Rails 8, Hotwire, Stimulus, RSpec, service objects |
| docker-devops | Containers | Multi-stage builds, Compose, CI/CD |
| telegram-bot | TG bots | aiogram, Telethon, Pyrogram, payments, Mini Apps, hybrid arch |
| discord-bot | Discord bots | discord.py, discord.js, cogs, slash commands |
| web3-defi | Blockchain | Uniswap v3/v4 hooks, rebalancing strategy, IL calc, multi-chain DEXs |
| saas-platform | SaaS | X API, scheduling, RSS, Prometheus monitoring |
| document-processing | Document AI | OCR (Tesseract/EasyOCR/Paddle), PDF tables, SAP RFC, validation engine |
| data-processing | Data/ETL | pandas, numpy, polars, Dask, visualization, optimization |
| database-patterns | Databases | PostgreSQL, Redis, SQLAlchemy async, caching |
| testing | Testing | pytest, Vitest, Playwright, TDD workflow |
| prompt-engineering | LLM | Claude API, structured output, model selection |
| mcp-servers | MCP | Configuration, security vetting, custom servers |

## Commands (10) - Slash Commands

| Command | Purpose |
|---------|---------|
| `/dev:code-review` | Comprehensive code review (quality, security, performance) |
| `/dev:plan` | Create implementation plan before coding |
| `/dev:tdd` | Test-driven development workflow (RED/GREEN/IMPROVE) |
| `/dev:debug` | Systematic debugging: reproduce -> isolate -> fix -> document |
| `/dev:refactor` | Safe refactoring with test verification |
| `/test:run` | Run tests with coverage, detect project type |
| `/project:init` | Initialize project with proper structure |
| `/project:status` | Project health check (code quality, tests, security, Docker) |
| `/deploy:docker-rebuild` | Rebuild containers and verify health |
| `/deploy:prod` | Production deployment checklist |

## Customization

### Adding Project-Specific Rules
Create `.claude/rules/99-project-specific.md`:
```yaml
---
paths:
  - "src/**/*.py"
---
# Your project-specific rules
```

### Adding Custom Skills
Create `.claude/skills/my-skill/SKILL.md`:
```yaml
---
name: my-skill
description: What this skill does.
---
# Skill content with patterns and examples
```

### Adding Custom Commands
Create `.claude/commands/namespace/command-name.md` as markdown.
Access via `/namespace:command-name` in Claude Code.
