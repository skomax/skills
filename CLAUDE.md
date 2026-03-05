# Project Configuration for Claude Code

## How This Works
This repository contains reusable Rules and Skills for Claude Code.
Copy the `.claude/` folder and this `CLAUDE.md` to any new project root.

## Rules (always active, filtered by file path globs)
Rules in `.claude/rules/` are automatically loaded based on file patterns.
They enforce standards for code quality, git, docker, testing, security, and documentation.

## Skills (activated by context)
Skills in `.claude/skills/` provide detailed guidance for specific domains.
Claude activates them automatically when working on matching tasks.

## Commands (slash commands)
Commands in `.claude/commands/` provide structured workflows:
- `/dev:code-review` - comprehensive code review
- `/dev:plan` - implementation planning
- `/dev:tdd` - test-driven development workflow
- `/dev:debug` - systematic debugging
- `/dev:refactor` - safe refactoring
- `/test:run` - run tests with coverage
- `/project:init` - initialize new project
- `/project:status` - project health check
- `/deploy:docker-rebuild` - rebuild and test Docker
- `/deploy:prod` - production deployment checklist

## Workflow
1. Before any task: read this file and relevant rules
2. Plan first, then implement (TDD when applicable)
3. After code changes to Docker or core config: rebuild and test containers
4. Commit with conventional commits format
5. Document significant changes in project changelog

## Framework Selection Guide
- **Telegram bots**: Python + aiogram 3.x (async, modern API)
- **Telegram userbots**: Python + Telethon or Pyrogram (MTProto)
- **Discord bots**: Python discord.py 2.x or Node.js discord.js 14.x
- **REST API backend**: Python FastAPI 0.115+ or Node.js Express 5.x
- **Full-stack web (React)**: Next.js 15 + React 19 + Tailwind CSS 4
- **Full-stack web (Ruby)**: Ruby on Rails 8 + Hotwire + Tailwind CSS
- **SaaS dashboards**: Next.js 15 + shadcn/ui + Supabase
- **Web3/DeFi**: Python web3.py 7+ / ethers.js 6.x + Solidity 0.8.x
- **Data processing**: Python pandas 2.x + numpy 2.x (or polars for speed)
- **Document/OCR processing**: Python + Anthropic SDK (Claude Vision)
- **Task queues**: Celery 5.x (Python) or BullMQ (Node.js)
- **Containerization**: Docker Compose for dev, Kubernetes for production

## Version Policy
Always verify and use the latest stable versions of frameworks.
Before starting a new project, check current versions via package registries.
Never use deprecated or end-of-life versions.
