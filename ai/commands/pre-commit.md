---
description: Pre-commit checks — verify tests, lint, review, and suggest commit message
allowed-tools: Read, Grep, Glob, Bash
---

# Pre-commit Command

Before making a commit, verify everything is ready.

## Steps

1. **Run CI** - Execute `make ci` (or equivalent tests + lint)
   - Report **exact** results (pass/fail counts)
   - If CI fails, **stop** and list what needs fixing
   - Do not proceed until CI passes

2. **Check related changes** - Are there unstaged changes that should be included?
   - Related files that were modified together
   - Test files for implementation changes
   - Documentation updates

3. **Review staged files** for:
   - Obvious errors or bugs
   - Security issues (secrets, SQL injection, etc.)
   - Readability and intention-revealing names
   - Simplification opportunities
   - Code that violates project conventions

4. **Verify test coverage**
   - Are there tests for the staged changes?
   - If new functionality, are there new tests?

5. **Show summary**
   ```
   Staged for commit:
   - lib/foo.rb (modified)
   - spec/foo_spec.rb (new)
   
   CI: ✅ 460 examples, 0 failures | 92 files, 0 offenses
   ```

6. **Suggest commit message**
   - Concise, imperative mood
   - Include scope if appropriate
   - Don't repeat what's obvious from the diff

## Commit Message Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer with trailers]
```

Types: feat, fix, refactor, test, docs, chore, style

Example:

```
feat(parser): Add support for string interpolation

AI-Generated-By: Claude Sonnet 4.5 (claude-sonnet-4-5-20250514) via Claude Code
```

## Checkpoints

- ❌ CI fails → Fix issues first
- ❌ Unrelated changes staged → Unstage or separate commits
- ❌ Missing tests → Consider adding tests
- ✅ All checks pass → Ready for commit
