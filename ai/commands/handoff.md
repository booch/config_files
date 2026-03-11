---
description: Create a handoff summary for session continuity
---

# Handoff Command

Create a concise handoff summary and save it to `.ai/context.md` for the next session.

## Summary Content

Write a brief (10-20 lines max) summary covering:

1. **What was done** - Key accomplishments this session (commits made, features implemented)

2. **Current state** - Any uncommitted work, partially completed tasks, or known issues

3. **Key decisions** - Important architectural or design decisions made that affect future work

4. **Next steps** - What logically comes next (be specific)

## Format

```markdown
# Session Context

**Last updated:** [date]
**Branch:** [current branch]

## Recent Work

- [bullet points of what was done]

## Current State

[any in-progress work or uncommitted changes]

## Key Decisions

- [decisions that affect future work]

## Next Steps

- [specific next actions]
```

## Notes

- Overwrite the previous context file (it's for the *next* session, not history)
- Be concise — this is working memory, not documentation
- Focus on what a fresh session needs to continue effectively
- Consider running `/retro` before `/handoff` to capture learnings
