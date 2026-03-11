---
description: Suggest a concise commit message for staged changes
allowed-tools: Bash
---

# Commit Message Command

Suggest a commit message for the currently staged changes.

## Steps

1. **Check staged changes**

    ```bash
    git --no-pager diff --cached --stat
    ```

    If nothing staged, check unstaged:

    ```bash
    git --no-pager diff --stat
    ```

2. **Stage changes if necessary**

    If there are no staged changes, determine what changes to stage for an
    atomic commit, and stage them.

3. **Analyze the changes**

    ```bash
    git --no-pager diff --cached  # or `git --no-pager diff` if nothing staged
    ```

    - What files changed?
    - What's the purpose of the change?
    - Is this a feature, fix, refactor, etc.?

4. **Suggest commit message**

## Commit Message Format

```
<scope>: <subject>

[optional body - only if needed]

[trailers]
```

### Guidelines

- **Subject line**: Imperative mood, <60 chars, no period
- **Body**: Explain "why" not "what" (the diff shows what)
- **Keep it concise**: Don't repeat what's obvious from the diff

### AI Attribution Trailers

When an AI tool is used to write or collaborate on code, use the appropriate
attribution. Examples:

```
AI-Generated-By: Claude Opus 4.6 (claude-opus-4-6) via GitHub Copilot
```

```
AI-Assisted-By: Claude Sonnet 4.5 (claude-sonnet-4-5-20250514) via Claude Code
```

