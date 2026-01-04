# AI Agent Instructions

This document provides high-level guidance for AI agents working on this codebase.
For detailed instructions on specific topics, see the skills in `skills/`.

## Core Philosophy

Code quality is measured by how easily and cheaply code can be modified for future needs.
Every decision should optimize for simplicity, maintainability, and readability.

## Skills Reference

The following skills provide detailed guidance:

- **sdlc** — Software development lifecycle, including code review process
- **design** — Software design principles (Simple Design, SOLID, coupling/cohesion)
- **code-quality** — Code style, naming, structure, and maintainability
- **testing** — Test philosophy, TDD, and test design
- **security** — Secure coding practices and OWASP Top 10

## Quick Reference

### The Four Rules of Simple Design (in priority order)

1. Passes the tests
2. Reveals intention
3. No duplication (DRY)
4. Fewest elements

### Code Review Process

All significant code changes require 3 sequential code reviews, each by a separate subagent, each followed by refactoring.
See the `sdlc` skill for details.

### Testing Philosophy

- Tests are executable specifications
- Tests are the first consumers of the API — design for the consumer first (TDD)
- Tests should be fast; avoid database access except when testing DB functionality itself

## Subagents

Subagents are specialized AI agents with focused roles. **Delegate to subagents proactively** — they keep the main context clean and apply specialized expertise.

### Available Subagents

- **explorer** — Understand unfamiliar code (fast, uses haiku)
- **test-writer** — Write tests following TDD philosophy
- **refactorer** — Simplify code while preserving behavior
- **code-reviewer-1** — Correctness and design review
- **code-reviewer-2** — Readability and simplicity review
- **code-reviewer-3** — Security and testing review

### Automatic Delegation Rules

**Always delegate to subagents when:**

- Asked to understand/explore unfamiliar code → use `explorer`
- Asked to write tests or do TDD → use `test-writer`
- Asked to simplify, clean up, or refactor → use `refactorer`
- After completing significant implementation → use `code-reviewer-1` to start 3-review process
- Asked to review code → use `code-reviewer-1` (triggers full review chain)

**Prefer to delegate to subagents as much as possible, especially when:**

- The task is specialized (exploration, testing, refactoring, security)
- Research would pollute the main context
- The same methodology should apply consistently

### Using Subagents

Invoke a subagent using the Task tool:

``` claude
Task(subagent_type="explorer", prompt="Understand how authentication works in src/auth/")
Task(subagent_type="test-writer", prompt="Write specs for the User#authenticate method")
Task(subagent_type="refactorer", prompt="Simplify src/billing/invoice.rb")
```

For the 3-review process, use the `/review` command which orchestrates all three reviewers sequentially.

### Subagent Best Practices

- Provide clear, complete context in the prompt — subagents don't see prior conversation
- Include specific file paths, not vague references
- Be specific about what output you expect
- Use sequential subagents when each depends on the previous (as in code review)
- Use parallel subagents for independent tasks

## Commands Reference

- `/pre-commit` — Run CI, review staged changes, suggest commit message
- `/commit-msg` — Suggest a commit message for staged changes
- `/review` — Run the 3-review code review process
- `/simplify` — Review code for simplification opportunities
- `/retro` — Retrospective on the current chat session
- `/what` — Suggest what to work on next
