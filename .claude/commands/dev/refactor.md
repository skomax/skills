# Safe Refactoring

Refactor code while maintaining correctness.

## Instructions

### Pre-refactoring
1. Ensure all tests pass (run full suite)
2. Check test coverage for the code being refactored
3. If coverage < 80%, write missing tests FIRST
4. Create a snapshot: `git stash` or commit current state

### Refactoring Rules
- **One change at a time**: don't mix refactoring with feature work
- **Run tests after each change**: catch regressions immediately
- **Preserve behavior**: output must remain identical
- **No API changes**: unless explicitly requested (that's a breaking change)

### Common Refactoring Patterns
1. **Extract function** - long function -> smaller focused functions
2. **Extract class** - large class -> smaller single-responsibility classes
3. **Rename** - unclear names -> descriptive names
4. **Remove duplication** - repeated code -> shared function (DRY after 3rd occurrence)
5. **Simplify conditionals** - nested if/else -> early returns, guard clauses
6. **Replace magic numbers** - hardcoded values -> named constants

### Execution
1. Identify the refactoring target and pattern
2. Write/verify tests cover current behavior
3. Apply ONE refactoring pattern
4. Run tests
5. If tests pass: commit with `refactor: <description>`
6. If tests fail: revert and investigate
7. Repeat for next pattern

### Post-refactoring
- Run full test suite
- Check that coverage hasn't decreased
- Review diff for unintended changes
- Verify Docker still builds if applicable
