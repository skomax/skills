# Systematic Debugging

Debug an issue using systematic approach.

## Instructions

### Phase 1: Reproduce
1. Get exact error message or unexpected behavior description
2. Find the minimal steps to reproduce
3. Check: is it consistent or intermittent?
4. Check: does it happen in all environments (dev/staging/prod)?

### Phase 2: Isolate
1. Read the error traceback/stack trace carefully
2. Identify the file and line where error originates
3. Check git log - when was this file last changed?
4. Check if the issue is in our code or a dependency

### Phase 3: Diagnose
1. Add targeted logging around the failing code
2. Check input data - is it what we expect?
3. Check environment: env vars, DB state, external service status
4. For Docker issues: `docker compose logs --tail=100 <service>`
5. For DB issues: check connections, locks, migration status

### Phase 4: Fix
1. Write a failing test that reproduces the bug
2. Fix the code (minimal change)
3. Run the test - it should pass now
4. Run full test suite to check for regressions
5. If Docker config changed: `docker compose up --build`

### Phase 5: Document
1. Add a comment explaining WHY the fix works (if not obvious)
2. Update CHANGELOG.md if it's a notable fix
3. Commit with: `fix: <description of what was broken>`

### Common Debug Commands
```bash
# Python
python -m pdb script.py        # Interactive debugger
python -c "import app; ..."    # Quick inline test

# Docker
docker compose logs -f --tail=100 app
docker compose exec app python -c "from app import db; print(db.url)"

# Database
docker compose exec db psql -U postgres -d app_db -c "SELECT count(*) FROM users;"

# Network
docker compose exec app curl -v http://api:8000/health
```
