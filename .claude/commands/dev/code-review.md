# Code Review

Perform a comprehensive code review of recent changes.

## Instructions

1. Determine what to review:
   - If `$ARGUMENTS` contains a branch/commit range, use: `git diff $ARGUMENTS`
   - For branch review: `git diff main...HEAD`
   - For staged changes: `git diff --staged`
   - Fallback: `git diff HEAD~1`
2. For each changed file, analyze:

### Code Quality
- Naming conventions (consistent with project style)
- Function length (max 50 lines)
- File length (max 500 lines)
- DRY violations (code duplication)
- Dead code or unused imports

### Security (OWASP Top 10)
- SQL injection vulnerabilities
- XSS potential
- Hardcoded secrets or credentials
- Input validation gaps
- Authentication/authorization issues

### Performance
- N+1 query problems
- Missing database indexes for new queries
- Unnecessary API calls or computation
- Memory leaks (unclosed connections, streams)

### Testing
- Are new features covered by tests?
- Are edge cases handled?
- Test quality (meaningful assertions, not just coverage)

3. Rate each issue: **CRITICAL** / **HIGH** / **MEDIUM** / **LOW**
4. Provide specific fix suggestions with code examples
5. Summarize: total issues found, blockers for merge, recommendations

See also: `/test:run` to verify tests pass before review
