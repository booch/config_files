---
description: Learn from experience — persist insights to improve future sessions
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Learn Command

Persist learnings from this session to improve future AI agent behavior.

## Usage

- `/learn` — Interactive mode, asks what to learn
- `/learn <insight>` — Learn a specific insight
- `/learn --from-retro` — Apply learnings from most recent `/retro` output

## What Can Be Learned

### 1. Project Knowledge

Technical facts about the codebase that help navigation and decision-making:

- Architecture patterns: "The visitor pattern is implemented in lib/stone/visitor.rb"
- Dependencies: "Grammy must be updated before Stone when changing parser rules"
- Gotchas: "LLVM requires DYLD_LIBRARY_PATH on macOS"

→ Stored in: `.ai/learnings.md` (project-specific)

### 2. Workflow Improvements

Process improvements based on what worked or didn't:

- "Always run `make lint` before committing grammar changes"
- "Ask clarifying questions about edge cases before writing tests"
- "Use Plan Mode for exploration, then switch to implementation"

→ Stored in: `AGENTS.md` or specific skill files

### 3. User Preferences

Personal working style that should be remembered:

- "Craig prefers seeing test names before implementation details"
- "Use 2-space indentation for Ruby, 4-space for everything else"
- "Challenge assumptions proactively"

→ Stored in: Global `~/.config/ai/AGENTS.md`

### 4. New Skills or Commands

When a workflow emerges that should be reusable:

- "We developed a pattern for migrating AST nodes — this should be a skill"
- "The grammar debugging workflow should be a command"

→ Creates new files in `skills/` or `commands/`

## Process

1. **Classify the learning** — Which category does it fit?
2. **Identify the target** — Which file should be updated?
3. **Propose the change** — Show the specific edit
4. **Get approval** — Wait for user confirmation
5. **Apply the change** — Edit the file
6. **Confirm** — Show what was updated

## Learning Format

When adding to `learnings.md`:

```markdown
## [Category]

### [Date] — [Brief Title]

**Context**: What situation led to this learning
**Insight**: The key takeaway
**Application**: How to apply this in the future
```

When updating `AGENTS.md` or skills:

- Keep changes minimal and focused
- Preserve existing structure
- Add to existing sections when possible
- Use clear, imperative language

## Guidelines

- Only persist things that will be useful in future sessions
- Be specific enough to be actionable
- Avoid duplicating existing guidance
- Keep learnings concise — they add to context size
- Review periodically to prune outdated learnings
