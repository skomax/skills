---
paths:
  - "**/*"
---
# Git Workflow Rules

## Commit Message Format
```
<type>: <description>

<optional body explaining WHY, not WHAT>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`, `style`

Examples:
- `feat: add Telegram bot webhook handler`
- `fix: resolve race condition in pool rebalancing`
- `refactor: extract liquidity calculation into separate module`
- `docs: add API endpoint documentation`

## Branch Strategy

- `main` - production-ready code, protected branch
- `dev` - integration branch for features
- `feature/<name>` - new features
- `fix/<name>` - bug fixes
- `hotfix/<name>` - urgent production fixes

Never push directly to `main`. Always use pull requests with review.

## PR Workflow

1. Analyze full commit history (not just latest commit)
2. Use `git diff <base-branch>...HEAD` to see all changes
3. Draft comprehensive PR summary with test plan
4. One PR per feature/fix - keep PRs focused and reviewable
5. Include description of what changed, why, and how to test

## Mandatory Before Commit

- [ ] All tests pass
- [ ] No linting errors
- [ ] No hardcoded secrets or credentials
- [ ] CHANGELOG.md updated for significant changes
- [ ] Docker rebuild tested if Dockerfile or docker-compose changed
- [ ] Documentation updated if public API changed

## Versioning

Follow Semantic Versioning (SemVer):
- MAJOR: breaking changes
- MINOR: new features, backward compatible
- PATCH: bug fixes, backward compatible
