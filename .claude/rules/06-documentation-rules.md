---
paths:
  - "**/*.md"
  - "**/docs/**"
  - "**/README*"
  - "**/CHANGELOG*"
  - "**/CLAUDE.md"
---
# Documentation Rules

## Project Documentation Structure

Every project must have:
```
README.md          - Project overview, setup instructions, usage
CHANGELOG.md       - Version history with dates and changes
docs/
  architecture.md  - System design, component diagram, data flow
  api.md           - API endpoints documentation (if applicable)
  deployment.md    - How to deploy, environments, CI/CD
  dev-setup.md     - Developer onboarding, local setup steps
```

## CLAUDE.md Management

- Keep under 150 lines (60 for critical section)
- Focus on: project context, key commands, architecture overview, conventions
- Update when project structure or key workflows change
- For monorepos: use nested CLAUDE.md files per package/service

## CHANGELOG.md Format

```markdown
## [1.2.0] - 2026-03-05
### Added
- New liquidity pool rebalancing strategy
- Telegram notification on position exit

### Changed
- Improved fee calculation accuracy for Uniswap v3

### Fixed
- Race condition in worker task distribution
```

## Code Documentation

- Document WHY, not WHAT (code should be self-documenting for WHAT)
- Public APIs: docstrings with parameters, return types, examples
- Complex algorithms: explain the approach and reasoning
- No redundant comments (don't comment obvious code)
- TODO format: `TODO(username): description [issue-link]`

## When to Update Documentation

- New feature added -> update README, add to CHANGELOG
- API changed -> update api.md
- Architecture changed -> update architecture.md
- Docker config changed -> update deployment.md and dev-setup.md
- Breaking change -> update CHANGELOG with migration guide

## Technical Logs

For complex projects maintain:
- `docs/decisions/` - Architecture Decision Records (ADR)
- `docs/worklog.md` - Development progress notes
- `docs/known-issues.md` - Known bugs and workarounds
