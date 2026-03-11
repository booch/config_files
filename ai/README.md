# AI Agent Configuration

This directory is the **source of truth** for AI agent configuration across multiple tools:

- Claude Code
- OpenCode
- GitHub Copilot CLI
- GitHub Copilot (VS Code)
- Windsurf
- Gemini CLI
- Codex
- Zed (partial)

## Directory Structure

```
~/.config/ai/
├── AGENTS.md           # Universal agent instructions
├── agents/             # Subagent definitions
│   ├── explorer/       # Codebase exploration
│   ├── code-reviewer-*/# Sequential code reviewers
│   ├── test-writer/    # TDD test writing
│   └── refactorer/     # Code refactoring
├── skills/             # Model-invoked capabilities
│   ├── tdd/            # Test-driven development
│   ├── refactor/       # Code refactoring
│   ├── learn/          # Self-improvement
│   ├── testing/        # Test philosophy
│   ├── design/         # Software design principles
│   ├── code-quality/   # Code style and quality
│   ├── sdlc/           # Software development lifecycle
│   └── security/       # Security practices
├── commands/           # User-invoked workflows
│   ├── tdd.md          # Start TDD workflow
│   ├── build.md        # Implement from tests/plan
│   ├── refactor.md     # Improve code structure
│   ├── retro.md        # Session retrospective
│   ├── learn.md        # Persist learnings
│   ├── remember.md     # Quick learning (alias)
│   └── explore.md      # Codebase exploration
└── README.md           # This file
```

## Syncing to Tools

Run `~/.config/install.sh` to create all symlinks (can be run from any directory).
See the [top-level README](../README.md#ai-tools) for the complete symlink table.

## Commands vs Skills vs Agents

| Type | Invoked By | Purpose |
|------|------------|---------|
| **Commands** | User (`/command`) | Explicit workflows |
| **Skills** | Model (automatic) | Capabilities to apply when relevant |
| **Agents** | Model (`Task()`) | Specialized subagents for delegation |

### When to Use Each

- **Command**: User wants to start a specific workflow (e.g., `/tdd`, `/review`)
- **Skill**: Model should automatically apply knowledge (e.g., TDD principles when writing tests)
- **Agent**: Delegate a task to preserve main context (e.g., exploration, code review)

## Tool-Specific Notes

### Claude Code

- Expects `CLAUDE.md` (symlinked from `AGENTS.md`)
- Full support for agents, skills, commands, hooks
- Location: `~/.config/claude/` or `~/.claude/`

### OpenCode

- Prefers `AGENTS.md` (native name)
- Skills via Superpowers plugin
- Agents via `@mention` system
- Location: `~/.config/opencode/`

### GitHub Copilot CLI

- Uses `copilot-instructions.md` in `~/.copilot/`
- `~/.copilot` symlinked to `~/.config/copilot/`
- Location: `~/.config/copilot/`

### GitHub Copilot (VS Code)

- Uses `agents.md` in `~/.config/github-copilot/instructions/`
- VS Code requires absolute path in `codeGeneration.instructions` setting
- Also reads project-level `.github/copilot-instructions.md`

### Windsurf

- Uses `global_rules.md` in `~/.codeium/windsurf/memories/`
- `~/.codeium` has mixed state; only `global_rules.md` is synced
- Project-level: `.windsurfrules` or `.windsurf/rules/`

### Gemini CLI

- Expects `GEMINI.md` (symlinked from `AGENTS.md`)
- `~/.gemini` symlinked to `~/.config/gemini/`
- Location: `~/.config/gemini/`

### Codex

- Uses `AGENTS.md`
- `~/.codex` symlinked to `~/.config/codex/`
- Location: `~/.config/codex/`

### Zed

- Different prompt structure
- Manual setup may be needed
- Location: `~/.config/zed/prompts/`

### Cursor

- Stores global/user rules in SQLite, not files (can't sync)
- Project-level: `.cursor/rules/*.mdc` (Markdown with YAML frontmatter)

## Project-Specific Configuration

For project-specific settings, create:

```
project/
├── .ai/                    # Tool-agnostic
│   ├── AGENTS.md           # Project instructions
│   ├── context.md          # Current session context
│   ├── learnings.md        # Project-specific learnings
│   └── explorer-cache/     # Cached exploration data
├── .claude/                # Claude Code specific
│   ├── CLAUDE.md           # (or symlink to .ai/AGENTS.md)
│   ├── settings.local.json # Project permissions
│   └── commands/           # Project-specific commands
└── AGENTS.md               # (alternative to .ai/AGENTS.md)
```

## What Goes Where

### Global (`~/.config/ai/`)

- Personal workflow preferences
- Universal coding standards
- Subagent definitions
- Generic skills and commands

### Project (`.ai/` or `.claude/`)

- Project architecture and structure
- Build commands and CI requirements
- Project-specific approval checkpoints
- Dependencies and tool versions
- Current context/handoff state
- Explorer cache

## Adding New Content

### New Skill

```bash
mkdir -p ~/.config/ai/skills/my-skill
cat > ~/.config/ai/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: When to use this skill...
---

# My Skill

Content here...
EOF
```

### New Command

```bash
cat > ~/.config/ai/commands/my-command.md << 'EOF'
---
description: What this command does
allowed-tools: Read, Write, Bash
---

# My Command

Instructions here...
EOF
```

### New Agent

```bash
mkdir -p ~/.config/ai/agents/my-agent
cat > ~/.config/ai/agents/my-agent/AGENT.md << 'EOF'
---
name: my-agent
description: When to use this agent...
tools: Read, Grep, Glob
model: haiku
---

# My Agent

Instructions here...
EOF
```

## Maintenance

- Run `~/.config/install.sh` after modifying content or pulling changes
- Review and prune learnings periodically
- Update skills when workflows evolve
- Keep AGENTS.md concise — it's loaded every session
