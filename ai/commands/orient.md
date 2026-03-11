---
description: Get oriented on current project state and ongoing work context
---

# Orient Command

Get oriented on the current project state for continuity across sessions.

## Steps

1. **Check for context file** - Read `.ai/context.md` (or `.claude/context.md`) if it exists for medium-term memory from previous sessions

2. **Check for learnings** - Read `.ai/learnings.md` if it exists for project-specific knowledge

3. **Git state** - Show current branch, uncommitted changes, recent commits (last 3-5)

4. **In-progress work** - Check for:
   - Staged but uncommitted changes
   - TODO comments added recently
   - Any work-in-progress indicated in context file

5. **Synthesize** - Provide a brief (5-10 line) orientation:
   - What was being worked on
   - Current state
   - Logical next step

Keep output concise. This is for quick orientation, not deep analysis.
