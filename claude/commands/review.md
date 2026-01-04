---
description: Run the 3-review SDLC code review process on recent changes
---

# Code Review Command

Initiate the 3-review code review process on recent changes or specified files.

## Process

Run three sequential code reviews using the dedicated reviewer subagents:

1. **code-reviewer-1**: Focus on correctness and design (SOLID, coupling/cohesion)
2. **code-reviewer-2**: Focus on readability and simplicity (Four Rules, Sandi Metz)
3. **code-reviewer-3**: Focus on security and testing (OWASP, test coverage)

## Steps

1. Identify what to review:
   - If files are specified, review those
   - Otherwise, review uncommitted changes (`git diff` and `git diff --staged`)
   - If no changes, ask what to review

2. Spawn **code-reviewer-1** as a subagent:
   - Pass the files/changes to review
   - Wait for review and refactoring to complete

3. Spawn **code-reviewer-2** as a subagent:
   - It reviews the refactored code from reviewer 1
   - Wait for review and refactoring to complete

4. Spawn **code-reviewer-3** as a subagent:
   - It reviews the refactored code from reviewer 2
   - Provides final security/testing assessment
   - Gives go/no-go verdict

5. Summarize the review process:
   - Key findings from each reviewer
   - Changes made during refactoring
   - Final verdict

## Usage Examples

- `/review` — Review uncommitted changes
- `/review src/auth/` — Review files in auth directory
- `/review src/user.rb src/user_spec.rb` — Review specific files
