---
description: Refactor code — improve structure while preserving behavior
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Refactor Command

Improve code structure, readability, and maintainability while preserving behavior.

## Usage

- `/refactor` — Refactor recent changes or staged files
- `/refactor <file-or-directory>` — Refactor specific code
- `/refactor --aggressive` — More aggressive refactoring (larger changes)

## Refactoring Process

### 1. Establish Safety Net

Before refactoring, ensure tests exist and pass:

```bash
make test  # or equivalent
```

If tests don't exist for the code being refactored, **stop and write tests first** or ask the user how to proceed.

### 2. Analyze the Code

Look for refactoring opportunities:

**Structural Issues**
- Long methods (>10 lines)
- Large classes (>200 lines)
- Deep nesting (>2 levels)
- Parallel class hierarchies

**Duplication**
- Copy-pasted code
- Similar method bodies
- Repeated conditionals

**Naming**
- Non-intention-revealing names
- Abbreviations or cryptic names
- Misleading names

**Coupling**
- Hardcoded dependencies
- Feature envy (method uses another class's data extensively)
- Inappropriate intimacy (classes know too much about each other)

**Complexity**
- Unnecessary abstractions
- Over-engineering
- Dead code

### 3. Propose Refactorings

Present findings with specific proposals:

```
I found these refactoring opportunities:

1. **Extract Method**: `process_order` (45 lines) → 4 smaller methods
   - `validate_order`
   - `calculate_totals`
   - `apply_discounts`
   - `finalize_order`

2. **Rename**: `x` → `order_total` (intention-revealing)

3. **Remove Duplication**: Lines 23-30 and 67-74 are nearly identical
   → Extract to `format_currency` helper

Would you like me to proceed with these refactorings?
```

### 4. Apply Refactorings

After approval:

1. Make one refactoring at a time
2. Run tests after each change
3. If tests fail, revert and reconsider

### 5. Verify

After all refactorings:

```bash
make ci  # All tests and linting must pass
```

## The Four Rules of Simple Design

Refactor toward these goals (in priority order):

1. **Passes the tests** — Never break existing behavior
2. **Reveals intention** — Code should be self-documenting
3. **No duplication** — DRY, but beware of wrong abstractions
4. **Fewest elements** — Remove unnecessary code

## Refactoring Catalog

Common refactorings to consider:

### Extract Method
Long method → Multiple focused methods

### Inline Method
Trivial delegation → Direct call

### Extract Class
Class doing too much → Multiple focused classes

### Rename
Unclear name → Intention-revealing name

### Replace Conditional with Polymorphism
Type-checking conditionals → Polymorphic behavior

### Introduce Parameter Object
Multiple related parameters → Single object

### Remove Dead Code
Unused code → Delete it

### Replace Magic Number with Constant
Literal values → Named constants

## Guidelines

- **Small steps**: Make one change at a time
- **Run tests frequently**: After every change
- **Don't mix refactoring and features**: Separate commits
- **Preserve behavior**: Tests should stay green
- **Know when to stop**: Perfect is the enemy of good
- **Consider the reader**: Optimize for readability
