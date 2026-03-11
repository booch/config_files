---
description: Build/implement from a plan — execute a prompt file or make tests pass
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Build Command

Implement code based on a plan, prompt file, or to make existing tests pass.

## Usage

- `/build` — Make failing tests pass (GREEN phase of TDD)
- `/build <prompt-file.md>` — Implement from a prompt/plan file
- `/build --continue` — Continue previous implementation

## Mode 1: Make Tests Pass (TDD GREEN)

When invoked without arguments after `/tdd`:

1. **Find failing tests**
   ```bash
   make test  # Identify what's failing
   ```

2. **Implement minimal code**
   - Write just enough to make tests pass
   - Don't add features not covered by tests
   - Don't optimize prematurely

3. **Run tests after each change**
   ```bash
   make test  # Should see progress
   ```

4. **Report completion**
   ```
   All tests pass. Implementation complete.
   
   Files created/modified:
   - lib/foo.rb (new)
   - lib/bar.rb (modified)
   
   Ready for refactoring? Use /refactor
   ```

## Mode 2: Implement from Prompt File

When given a prompt file path:

1. **Read the prompt file**
   - Understand requirements and constraints
   - Note any specific instructions

2. **Plan the implementation**
   - Identify files to create/modify
   - Determine order of operations
   - Note dependencies

3. **Execute the plan**
   - Implement step by step
   - Run tests frequently
   - Update the prompt file with progress/notes

4. **Verify completion**
   ```bash
   make ci  # All tests and linting must pass
   ```

5. **Report results**
   ```
   Implementation complete based on <prompt-file.md>
   
   Created:
   - lib/feature.rb
   - spec/feature_spec.rb
   
   Modified:
   - lib/main.rb
   
   CI status: ✅ All passing
   
   Commit the prompt file with the implementation? [Y/n]
   ```

## Prompt File Format

A prompt file (`.md`) should contain:

```markdown
# Feature: [Name]

## Requirements

- [Requirement 1]
- [Requirement 2]

## Constraints

- [Constraint 1]

## Implementation Notes

[Any specific guidance]

## Progress

- [ ] Step 1
- [ ] Step 2
- [x] Step 3 (completed)

## Clarifications

[Answers to questions, user decisions]
```

## Implementation Guidelines

### Minimal Implementation

Write the simplest code that makes tests pass:

```ruby
# Test expects: Calculator.add(2, 3) => 5

# Good: Minimal implementation
def add(a, b)
  a + b
end

# Bad: Over-engineered
def add(a, b)
  validate_numeric(a, b)
  result = perform_addition(a, b)
  log_operation(:add, a, b, result)
  result
end
```

### Incremental Progress

- Implement one test at a time
- Run tests after each change
- Commit working increments

### When Stuck

If implementation is unclear:

1. Re-read the test to understand expected behavior
2. Check existing code for patterns
3. Ask the user for clarification

Don't guess — tests should guide implementation.

## Checkpoints

- **Tests must pass** before reporting completion
- **CI must pass** before suggesting commit
- **Prompt file updated** with progress and clarifications

## What Comes Next

After `/build`:

- `/refactor` — Improve code structure
- `/review` — Code review
- `/commit-msg` — Prepare for commit
