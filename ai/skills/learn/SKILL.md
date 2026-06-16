---
name: learn
description: Persist learnings and insights across sessions. Use when the AI discovers something worth remembering, when a workflow pattern should be documented, when a mistake reveals a gap in instructions, or when the user asks to remember something.
---

# Learn Skill

Persist learnings so future sessions start smarter.

## When to Use

- A debugging session reveals a non-obvious cause
- A workflow pattern proves effective and should be repeated
- A mistake reveals missing guidance
- The user says "learn", "remember this", "don't forget", or similar
- A retrospective identifies actionable improvements
- You discover undocumented project-specific knowledge

## Categories

| Type | Scope | Description |
|------|-------|-------------|
| `project` | Project | Technical facts, architecture, gotchas for this codebase |
| `feedback` | Either | How the user likes to work — corrections AND confirmations |
| `user` | Global | User's role, preferences, responsibilities, knowledge |
| `reference` | Either | Pointers to external systems (Linear, Grafana, Slack, etc.) |

## Storage Locations

- **Project learnings**: `<project>/.ai/memory/`
- **Global learnings**: `${XDG_DATA_HOME:-~/.local/share}/ai/memory/`

Paths follow the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/latest/).
`XDG_DATA_HOME` defaults to `~/.local/share`; `XDG_CONFIG_HOME` defaults to `~/.config`.

Each directory contains:
- `MEMORY.md` — index of all learnings (one line per entry, under 150 chars)
- Individual `.md` files with YAML frontmatter

## File Format

```markdown
---
name: Short descriptive title
description: One-line summary used to judge relevance in future sessions
type: project | feedback | user | reference
---

The learning content in Markdown.

For feedback and project types, structure as:
**Why:** The reason or context behind this learning.
**How to apply:** When and how to use this in the future.
```

## MEMORY.md Format

```markdown
- [Title](filename.md) — one-line hook describing when this is relevant
```

Keep entries under 150 characters. This file is loaded into context at session
start, so keep it concise. Content goes in the individual files, not here.

## Process

1. **Classify** the learning — determine where it belongs:

   | If the learning is... | Route to |
   |---|---|
   | A project-specific fact, gotcha, or reference | Project memory (`.ai/memory/`) |
   | A personal preference, role detail, or global reference | Global memory (`${XDG_DATA_HOME:-~/.local/share}/ai/memory/`) |
   | A workflow improvement that fits an existing skill | Update the skill file directly |
   | A universal guideline or workflow rule | Update global AGENTS.md (`${XDG_CONFIG_HOME:-~/.config}/ai/AGENTS.md`) |
   | A project-specific guideline or convention | Update the project's AGENTS.md |
   | A new reusable workflow pattern | Propose a new skill or command |

2. **Check for duplicates**: For memory files, read the relevant `MEMORY.md`. For skill or AGENTS.md updates, read the target file. Update existing content rather than duplicating.

3. **Bootstrap storage** (if routing to memory): See "First-Use Setup" below.

4. **Apply the learning**:
   - **Memory file**: Write the file, update `MEMORY.md` index
   - **Skill update**: Edit the skill file directly
   - **AGENTS.md update**: Edit the relevant section
   - **New skill/command**: Propose the content and location, get approval

5. **Confirm**: Tell the user what was persisted and where

## First-Use Setup

On first use, the skill bootstraps storage lazily. Perform these steps
as needed — skip any that are already done.

### Project Memory Setup

```bash
PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMORY_DIR="${PROJECT_DIR}/.ai/memory"

# Create project memory directory and index
mkdir -p "$MEMORY_DIR"
touch "$MEMORY_DIR/MEMORY.md"

# Set up Claude Code symlink
HASH=$(echo "$PROJECT_DIR" | sed 's|/|-|g')
CLAUDE_MEM="$HOME/.claude/projects/${HASH}/memory"

if [ -L "$CLAUDE_MEM" ]; then
  : # Already a symlink — nothing to do
elif [ -d "$CLAUDE_MEM" ]; then
  # Claude auto-memory exists — migrate files and replace with symlink
  cp -n "$CLAUDE_MEM"/* "$MEMORY_DIR/" 2>/dev/null
  rm -rf "$CLAUDE_MEM"
  ln -s "$MEMORY_DIR" "$CLAUDE_MEM"
else
  # Does not exist — create symlink
  mkdir -p "$(dirname "$CLAUDE_MEM")"
  ln -s "$MEMORY_DIR" "$CLAUDE_MEM"
fi
```

### Global Memory Setup

```bash
GLOBAL_MEM="${XDG_DATA_HOME:-$HOME/.local/share}/ai/memory"
mkdir -p "$GLOBAL_MEM"
touch "$GLOBAL_MEM/MEMORY.md"
```

### AGENTS.md Update

On first use, check if `${XDG_CONFIG_HOME:-~/.config}/ai/AGENTS.md` already has a
`## Memory` section. If not, add this section (find an appropriate location in the file):

```markdown
## Memory

AI tools persist learnings in Markdown files with YAML frontmatter.

- **Global**: `${XDG_DATA_HOME:-~/.local/share}/ai/memory/MEMORY.md` — personal preferences, workflow patterns
- **Project**: `.ai/memory/MEMORY.md` — project-specific knowledge and context

Read both `MEMORY.md` files at session start (they are concise indexes).
Load individual memory files only when relevant to the current task.
```

## Guidelines

- Only persist things useful in future sessions
- Be specific enough to be actionable
- Keep learnings concise — they consume context
- Avoid duplicating existing guidance
- Never persist without user confirmation (unless auto-learning)
- Review periodically to prune outdated learnings
- Prefer updating an existing learning over creating a new one

## Integration

- `/learn` — Interactive learning, or `/learn <insight>` for quick capture
- `/remember` — Alias for `/learn`
- `/retro` — Session retrospective that identifies learnings; use `/learn --from-retro` to persist them
