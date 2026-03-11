---
name: coding
description: Code implementation and feature development. Use this skill when implementing features, fixing bugs, or making tests pass. This is the GREEN phase of TDD — write minimal code to pass tests, then refactor. Also use the tdd, refactor, and design skills.
---

# Coding Skill

This skill guides code implementation — the GREEN phase of TDD.

## Core Process

1. **Understand the tests** — Read failing tests to understand required behavior
2. **Implement minimally** — Write the simplest code that makes tests pass
3. **Refactor** — Improve structure while keeping tests green (invoke the `refactor` skill)

## Related Skills

- **tdd** — Writing tests (RED phase) before implementation
- **refactor** — Improving code structure (REFACTOR phase) after tests pass
- **design** — Software design principles for architectural decisions
- **code-quality** — Naming, structure, and maintainability guidelines
- **security** — Secure coding practices

## Principles

### Follow Existing Patterns

Before writing new code:

- Read surrounding code to understand conventions
- Match the style, naming, and structure of the existing codebase
- Reuse existing abstractions rather than creating new ones

### Simplicity

- Solve the immediate problem, not hypothetical future ones
- Prefer clear, readable code over clever code
- Each method should do one thing at one level of abstraction

### Immutability

- Initialize all state in constructors
- Avoid mutating objects after creation
- Exception: memoization/lazy initialization is acceptable

### Error Handling

- Validate at system boundaries (user input, external APIs)
- Trust internal code and framework guarantees
- Provide helpful error messages

## Workflow Integration

After implementation:

1. Run tests to verify they pass
2. Run linting to check style
3. Invoke the `refactor` skill for cleanup
4. Request code review via the SDLC process
