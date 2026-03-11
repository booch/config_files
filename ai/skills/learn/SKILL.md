---
name: learn
description: Self-improvement through experience. Use this skill when the AI agent discovers something that should be remembered for future sessions, when a workflow pattern emerges that should be documented, when a mistake reveals a gap in instructions, or when the user explicitly asks to remember something.
---

# Learn Skill

This skill enables AI agents to learn from experience by persisting insights that improve future sessions.

## When to Invoke This Skill

Automatically consider learning when:

- A debugging session reveals a non-obvious cause
- A workflow pattern proves effective and should be repeated
- A mistake reveals missing guidance in AGENTS.md
- The user says "remember this" or "don't forget"
- A retrospective identifies actionable improvements
- You discover project-specific knowledge that isn't documented

## Categories of Learnings

### Project Knowledge

Technical facts about the codebase:

```markdown
## Project Knowledge

### 2025-01-16 — Grammy Parser Dependency

**Context**: Changed grammar rules in Stone without updating Grammy first
**Insight**: Grammy is a local dependency; changes must be coordinated
**Application**: When modifying parser rules, check if Grammy needs updates first
```

**Storage**: `.ai/learnings.md` (project-specific)

### Workflow Improvements

Process improvements based on experience:

```markdown
## Workflow

- Always run `make lint` before committing grammar changes — catches 
  formatting issues that break the parser
- Use Plan Mode for codebase exploration to avoid premature implementation
```

**Storage**: `AGENTS.md` (project or global, depending on scope)

### User Preferences

Personal working style to remember:

```markdown
## User Preferences

- Craig prefers concise commit messages without redundant context
- Challenge assumptions proactively; he values pushback
- Use 2-space indentation for Ruby, 4-space elsewhere
```

**Storage**: Global `~/.config/ai/AGENTS.md`

### Skill/Command Candidates

When a pattern emerges that should be a reusable workflow:

```markdown
## Potential Skills/Commands

- **AST Node Migration**: A 5-step pattern emerged for adding new AST nodes
- **Grammar Debugging**: A systematic approach for parser issues
```

**Storage**: Propose creating new skill/command files

## Storage Locations

| Type | Scope | Location |
|------|-------|----------|
| Project knowledge | Project | `.ai/learnings.md` |
| Workflow (project) | Project | `.ai/AGENTS.md` |
| Workflow (universal) | Global | `~/.config/ai/AGENTS.md` |
| User preferences | Global | `~/.config/ai/AGENTS.md` |
| New skill | Global | `~/.config/ai/skills/<name>/SKILL.md` |
| New command | Global | `~/.config/ai/commands/<name>.md` |

## Learning Process

1. **Recognize the learning opportunity**
   - Something unexpected happened
   - A pattern proved effective
   - User explicitly requests remembering

2. **Classify the learning**
   - What category does it fit?
   - Is it project-specific or universal?

3. **Formulate the insight**
   - Be specific and actionable
   - Include context for understanding
   - Describe how to apply it

4. **Propose the change**
   - Show the exact file and edit
   - Explain why this helps

5. **Get approval**
   - Never persist without user confirmation
   - Changes affect all future sessions

6. **Apply and confirm**
   - Make the edit
   - Summarize what was persisted

## Guidelines

- **Be selective**: Only persist insights that will help future sessions
- **Be specific**: Vague learnings aren't actionable
- **Be concise**: Learnings add to context window size
- **Avoid duplication**: Check if guidance already exists
- **Review periodically**: Suggest pruning outdated learnings
- **Respect approval**: Never auto-commit learning changes

## Integration with Other Commands

- `/retro` generates learnings → `/learn` persists them
- `/remember <x>` is shorthand for quick learning
- `/handoff` may reference learnings for session continuity
