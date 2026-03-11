---
description: Start a TDD workflow — write tests first, then implement
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# TDD Command

Start a Test-Driven Development workflow for a feature, fix, or change.

## Usage

- `/tdd` — Interactive mode, asks clarifying questions
- `/tdd <description>` — Start TDD for the described work

## Phase 1: Understand (if no arguments provided)

When invoked without arguments or with vague requirements:

1. **Ask clarifying questions** to understand:
   - What behavior should be implemented?
   - What are the expected inputs and outputs?
   - Are there edge cases to consider?
   - What existing code is affected?

2. **Gather context**:
   - Search for related code and tests
   - Understand existing patterns
   - Identify integration points

3. **Summarize understanding**:
   - "Here's what I understand: [summary]"
   - "Is this correct? Any clarifications?"

**Do not proceed until requirements are clear.**

## Phase 2: Specify (write tests)

Once requirements are clear:

1. **Design the API** by thinking about how tests will use it
   - What interface would be most convenient for callers?
   - Let tests drive the API design

2. **Write failing tests** that specify the expected behavior
   - Each test should verify one behavior
   - Use descriptive names that read as specifications
   - Include edge cases and error conditions

3. **Run tests to confirm they fail**
   - Tests should fail because the implementation doesn't exist
   - If tests pass, something is wrong

4. **Present tests for review**:
   ```
   Here are the tests I've written:
   
   [test code]
   
   These tests specify:
   - [behavior 1]
   - [behavior 2]
   - [edge case handling]
   
   Ready to proceed with implementation?
   ```

**STOP HERE** — Wait for explicit approval before implementing.

## Approval Checkpoint

The user must explicitly approve before proceeding:

- ✅ "looks good", "go ahead", "proceed", "continue", "approved"
- ❌ "wait", "hold on", "let me think", "not yet", silence

If changes are requested, update tests and re-present for approval.

## What Happens Next

After tests are approved, the user can:

- `/build` — Implement the code to make tests pass
- Continue manually with implementation
- Ask for implementation directly

The TDD command focuses on the **specification phase**. Implementation, refactoring, and review are separate concerns:

- **Implementation**: `/build` or manual
- **Refactoring**: `/refactor`
- **Review**: `/review`

## Guidelines

- Tests are executable specifications — write them like documentation
- Prefer fast, isolated unit tests over slow integration tests
- Mock external dependencies, not internal modules
- One assertion per test when practical
- Use intention-revealing names
- Don't hit the database unless testing database behavior
