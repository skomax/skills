# TDD Workflow

Implement a feature using Test-Driven Development.

## Instructions

Follow this strict sequence:

### Phase 1: RED (Write Failing Test)
1. Understand the feature requirements
2. Write a test that describes the expected behavior
3. Run the test - confirm it **FAILS**
4. If test passes immediately, the test is wrong or feature already exists

### Phase 2: GREEN (Make It Pass)
1. Write the **minimal** code to make the test pass
2. Do not optimize or add extra functionality
3. Run the test - confirm it **PASSES**
4. Run all related tests to ensure no regressions

### Phase 3: REFACTOR
1. Refactor the code for clarity and quality
2. Remove duplication
3. Improve naming
4. Run all tests again - they must still pass

### Phase 4: Verify
1. Check coverage: `pytest --cov=src -v` or `npm test -- --coverage`
2. Ensure coverage >= 80% for the new code
3. Add edge case tests if coverage is low

### Report
After completion, show:
- Number of tests added
- Coverage percentage
- Any issues found during TDD cycle
