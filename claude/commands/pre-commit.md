---
description: Pre-commit checks: verify tests, lint, and suggest commit message
---

# Pre-commit Command

Before I make a commit:

1. Run `make ci` (tests + lint) - report **exact** results
   - If CI fails, stop and list what needs fixing
2. Determine if there are changes to other files that should be committed together
3. Review staged files for:
   - Obvious errors or security issues
   - Readability and intention-revealing names
   - Simplification opportunities
4. Verify appropriate test coverage for staged code
5. Show me what's staged (summary)
6. Suggest a commit message

**CI must pass before suggesting a commit message.**
